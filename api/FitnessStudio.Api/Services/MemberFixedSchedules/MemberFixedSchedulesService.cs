using System.Data;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Domain.Members;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FitnessStudio.Api.Services.MemberFixedSchedules;

public class MemberFixedSchedulesService : IMemberFixedSchedulesService
{
    private static readonly HashSet<string> AllowedStatuses = ["active", "paused", "cancelled"];
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;
    private readonly IMembershipBookingPolicy _membershipBookingPolicy;

    public MemberFixedSchedulesService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser,
        IMembershipBookingPolicy membershipBookingPolicy)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _membershipBookingPolicy = membershipBookingPolicy;
    }

    public Task<List<MemberFixedScheduleResponse>> GetSchedulesAsync()
    {
        return Project(QuerySchedules()
            .OrderBy(schedule => schedule.RecurringSchedule.DayOfWeek)
            .ThenBy(schedule => schedule.RecurringSchedule.StartsAtTime))
            .ToListAsync();
    }

    public async Task<List<MemberFixedScheduleResponse>> GetCurrentMemberSchedulesAsync()
    {
        if (!_currentUser.MemberId.HasValue)
        {
            return [];
        }

        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));

        return await Project(_dbContext.MemberFixedSchedules
                .AsNoTracking()
                .Where(schedule =>
                    schedule.StudioId == _currentUser.StudioId
                    && schedule.MemberId == _currentUser.MemberId.Value
                    && schedule.Status == "active"
                    && schedule.StartsOn <= today
                    && (!schedule.EndsOn.HasValue || schedule.EndsOn.Value >= today))
                .OrderBy(schedule => schedule.RecurringSchedule.DayOfWeek)
                .ThenBy(schedule => schedule.RecurringSchedule.StartsAtTime))
            .ToListAsync();
    }

    public async Task<ServiceResult<MemberFixedScheduleResponse>> GetScheduleAsync(long id)
    {
        var schedule = await Project(QuerySchedules().Where(item => item.Id == id)).FirstOrDefaultAsync();

        return schedule is null
            ? ServiceResult<MemberFixedScheduleResponse>.NotFound(
                "Member fixed schedule not found.",
                "A fixed schedule with this id does not exist.")
            : ServiceResult<MemberFixedScheduleResponse>.Success(schedule);
    }

    public async Task<ServiceResult<MemberFixedScheduleResponse>> CreateScheduleAsync(
        CreateMemberFixedScheduleRequest request)
    {
        var now = DateTime.UtcNow;
        await using var transaction = await _dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable);

        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return new ServiceResult<MemberFixedScheduleResponse>(
                validationResult.Status,
                default,
                validationResult.Error);
        }

        var memberStatus = await _dbContext.Members
            .Where(member =>
                member.Id == request.MemberId
                && member.StudioId == _currentUser.StudioId)
            .Select(member => member.Status)
            .SingleAsync();
        if (memberStatus != MemberStatuses.Active)
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Member is not active.",
                "Only active members can be assigned to a fixed schedule.");
        }

        var recurringSchedule = await _dbContext.RecurringClassSchedules
            .Include(item => item.ClassSessions.Where(session => session.StartsAt >= now))
                .ThenInclude(session => session.Bookings)
            .SingleAsync(schedule =>
                schedule.Id == request.RecurringScheduleId
                && schedule.StudioId == _currentUser.StudioId);
        if (recurringSchedule.Status != "active")
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Recurring schedule is not active.",
                "Members can be assigned only to an active recurring schedule.");
        }

        var alreadyAssigned = await _dbContext.MemberFixedSchedules.AnyAsync(item =>
            item.StudioId == _currentUser.StudioId
            && item.MemberId == request.MemberId
            && item.RecurringScheduleId == request.RecurringScheduleId
            && (item.Status == "active" || item.Status == "paused"));
        if (alreadyAssigned)
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Fixed schedule already exists.",
                "This member already has an active or paused assignment to the recurring schedule.");
        }

        var assignedMemberCount = await _dbContext.MemberFixedSchedules.CountAsync(item =>
            item.StudioId == _currentUser.StudioId
            && item.RecurringScheduleId == request.RecurringScheduleId
            && item.Status == "active"
            && (!item.EndsOn.HasValue || item.EndsOn.Value >= request.StartsOn)
            && (!request.EndsOn.HasValue || item.StartsOn <= request.EndsOn.Value));
        if (assignedMemberCount >= recurringSchedule.Capacity)
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Recurring schedule is full.",
                "The recurring schedule has no available fixed places.");
        }

        await _membershipBookingPolicy.AcquireMemberLockAsync(request.MemberId);

        var assignmentEndsOn = request.EndsOn.HasValue
            && (!recurringSchedule.ValidUntil.HasValue
                || request.EndsOn.Value < recurringSchedule.ValidUntil.Value)
            ? request.EndsOn
            : recurringSchedule.ValidUntil;
        if (!await FixedSchedulePackagePolicy.AllowsAssignmentAsync(
                _dbContext,
                _currentUser.StudioId,
                request.MemberId,
                request.StartsOn,
                assignmentEndsOn))
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Membership package limit reached.",
                "The member's membership package does not allow another fixed schedule.");
        }

        var schedule = new MemberFixedSchedule
        {
            StudioId = _currentUser.StudioId,
            MemberId = request.MemberId,
            RecurringScheduleId = request.RecurringScheduleId,
            StartsOn = request.StartsOn,
            EndsOn = request.EndsOn,
            Status = Normalize(request.Status),
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.MemberFixedSchedules.Add(schedule);

        try
        {
            await _dbContext.SaveChangesAsync();

            var timezoneId = await _dbContext.Studios
                .Where(studio => studio.Id == _currentUser.StudioId)
                .Select(studio => studio.Timezone)
                .SingleAsync();
            var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);

            foreach (var session in recurringSchedule.ClassSessions
                .Where(item => item.Status == ClassSessionStatuses.Scheduled)
                .OrderBy(item => item.StartsAt))
            {
                var localDate = DateOnly.FromDateTime(
                    TimeZoneInfo.ConvertTimeFromUtc(session.StartsAt, timezone));
                if (localDate < request.StartsOn
                    || (request.EndsOn.HasValue && localDate > request.EndsOn.Value))
                {
                    continue;
                }

                var existingBooking = session.Bookings
                    .FirstOrDefault(item => item.MemberId == request.MemberId);
                var membershipDecision = await _membershipBookingPolicy.EvaluateAsync(
                    request.MemberId,
                    session.StartsAt,
                    existingBooking?.Id);
                if (!membershipDecision.IsAllowed)
                {
                    continue;
                }

                var occupied = session.Bookings.Count(item =>
                    item.MemberId != request.MemberId
                    && BookingStatuses.CapacityCounting.Contains(item.Status));
                var bookingStatus = occupied < session.Capacity
                    ? BookingStatuses.Booked
                    : BookingStatuses.Waitlisted;

                if (existingBooking is null)
                {
                    session.Bookings.Add(new Booking
                    {
                        StudioId = _currentUser.StudioId,
                        MemberId = request.MemberId,
                        BookingSource = "fixed_schedule",
                        Status = bookingStatus,
                        BookedAt = now,
                        CreatedAt = now,
                        UpdatedAt = now
                    });
                }
                else
                {
                    existingBooking.Status = bookingStatus;
                    existingBooking.BookingSource = "fixed_schedule";
                    existingBooking.CancelledAt = null;
                    existingBooking.CancellationReason = null;
                    existingBooking.UpdatedAt = now;
                }

                // Persist each reservation so membership usage checks for later
                // sessions in the same transaction include earlier reservations.
                await _dbContext.SaveChangesAsync();
            }

            await transaction.CommitAsync();
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync();
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Fixed schedule already exists.",
                "The fixed schedule changed while the member was being assigned.");
        }
        catch (PostgresException exception)
            when (exception.SqlState == PostgresErrorCodes.SerializationFailure)
        {
            await transaction.RollbackAsync();
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Fixed schedule cannot be created.",
                "The fixed schedule changed while the member was being assigned.");
        }

        return await GetScheduleAsync(schedule.Id);
    }

    public async Task<ServiceResult> UpdateScheduleAsync(long id, UpdateMemberFixedScheduleRequest request)
    {
        await using var transaction = await _dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable);

        var schedule = await _dbContext.MemberFixedSchedules.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult.NotFound(
                "Member fixed schedule not found.",
                "A fixed schedule with this id does not exist.");
        }

        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return validationResult;
        }

        var normalizedStatus = Normalize(request.Status);
        var activeAssignmentChangesScope = normalizedStatus == "active"
            && (schedule.Status != "active"
                || schedule.MemberId != request.MemberId
                || schedule.RecurringScheduleId != request.RecurringScheduleId
                || schedule.StartsOn != request.StartsOn
                || schedule.EndsOn != request.EndsOn);
        if (activeAssignmentChangesScope)
        {
            await _membershipBookingPolicy.AcquireMemberLockAsync(request.MemberId);
            var targetValidUntil = await _dbContext.RecurringClassSchedules
                .Where(item =>
                    item.Id == request.RecurringScheduleId
                    && item.StudioId == _currentUser.StudioId)
                .Select(item => item.ValidUntil)
                .SingleAsync();
            var assignmentEndsOn = request.EndsOn.HasValue
                && (!targetValidUntil.HasValue || request.EndsOn.Value < targetValidUntil.Value)
                ? request.EndsOn
                : targetValidUntil;
            if (!await FixedSchedulePackagePolicy.AllowsAssignmentAsync(
                    _dbContext,
                    _currentUser.StudioId,
                    request.MemberId,
                    request.StartsOn,
                    assignmentEndsOn,
                    schedule.Id))
            {
                return ServiceResult.Conflict(
                    "Membership package limit reached.",
                    "The member's membership package does not allow another fixed schedule.");
            }
        }

        schedule.MemberId = request.MemberId;
        schedule.RecurringScheduleId = request.RecurringScheduleId;
        schedule.StartsOn = request.StartsOn;
        schedule.EndsOn = request.EndsOn;
        schedule.Status = normalizedStatus;
        schedule.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Fixed schedule cannot be updated.",
                "This member already has an active or paused assignment to the recurring schedule.");
        }

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteScheduleAsync(long id)
    {
        var schedule = await _dbContext.MemberFixedSchedules.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult.NotFound(
                "Member fixed schedule not found.",
                "A fixed schedule with this id does not exist.");
        }

        _dbContext.MemberFixedSchedules.Remove(schedule);
        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> MoveScheduleAsync(
        long id,
        MoveMemberFixedScheduleRequest request)
    {
        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var now = DateTime.UtcNow;

        await using var transaction = await _dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable);

        var source = await _dbContext.MemberFixedSchedules
            .Include(item => item.RecurringSchedule)
            .FirstOrDefaultAsync(item => item.Id == id && item.StudioId == _currentUser.StudioId);

        if (source is null)
        {
            return ServiceResult.NotFound(
                "Member fixed schedule not found.",
                "A fixed schedule with this id does not exist.");
        }

        var target = await _dbContext.RecurringClassSchedules
            .Include(item => item.ClassSessions.Where(session => session.StartsAt >= now))
                .ThenInclude(session => session.Bookings)
            .FirstOrDefaultAsync(item =>
                item.Id == request.TargetRecurringScheduleId
                && item.StudioId == _currentUser.StudioId);

        if (target is null)
        {
            return ServiceResult.NotFound(
                "Target recurring schedule not found.",
                "A target recurring schedule with this id does not exist.");
        }

        var sourceAuthorization = AuthorizeSchedule(source.RecurringSchedule);
        var targetAuthorization = AuthorizeSchedule(target);
        if (sourceAuthorization is not null || targetAuthorization is not null)
        {
            return ServiceResult.Forbidden(
                "Fixed schedule cannot be moved.",
                "Trainers can move members only between their own recurring schedules.");
        }

        if (source.RecurringScheduleId == target.Id)
        {
            return ServiceResult.Conflict(
                "Fixed schedule cannot be moved.",
                "The source and target recurring schedules must be different.");
        }

        if (source.Status != "active"
            || source.StartsOn > today
            || (source.EndsOn.HasValue && source.EndsOn.Value < today))
        {
            return ServiceResult.Conflict(
                "Fixed schedule cannot be moved.",
                "Only a currently active fixed schedule assignment can be moved.");
        }

        if (target.Status != "active"
            || target.ValidFrom > today
            || (target.ValidUntil.HasValue && target.ValidUntil.Value < today))
        {
            return ServiceResult.Conflict(
                "Target recurring schedule is unavailable.",
                "The target recurring schedule must be active today.");
        }

        var alreadyAssigned = await _dbContext.MemberFixedSchedules.AnyAsync(item =>
            item.StudioId == _currentUser.StudioId
            && item.MemberId == source.MemberId
            && item.RecurringScheduleId == target.Id
            && (item.Status == "active" || item.Status == "paused"));
        if (alreadyAssigned)
        {
            return ServiceResult.Conflict(
                "Member is already assigned.",
                "The member already has an active assignment to the target recurring schedule.");
        }

        var targetMemberCount = await _dbContext.MemberFixedSchedules.CountAsync(item =>
            item.StudioId == _currentUser.StudioId
            && item.RecurringScheduleId == target.Id
            && item.Status == "active"
            && item.StartsOn <= today
            && (!item.EndsOn.HasValue || item.EndsOn.Value >= today));
        if (targetMemberCount >= target.Capacity)
        {
            return ServiceResult.Conflict(
                "Target recurring schedule is full.",
                "The target recurring schedule has no available fixed places.");
        }

        await _membershipBookingPolicy.AcquireMemberLockAsync(source.MemberId);

        var originalEndsOn = source.EndsOn;
        source.Status = "cancelled";
        source.EndsOn = today > source.StartsOn ? today.AddDays(-1) : source.StartsOn;
        source.UpdatedAt = now;

        var targetEndsOn = originalEndsOn;
        if (target.ValidUntil.HasValue
            && (!targetEndsOn.HasValue || target.ValidUntil.Value < targetEndsOn.Value))
        {
            targetEndsOn = target.ValidUntil;
        }

        var targetAssignment = new MemberFixedSchedule
        {
            StudioId = _currentUser.StudioId,
            MemberId = source.MemberId,
            RecurringScheduleId = target.Id,
            StartsOn = today,
            EndsOn = targetEndsOn,
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        _dbContext.MemberFixedSchedules.Add(targetAssignment);

        var sourceBookings = await _dbContext.Bookings
            .Include(booking => booking.ClassSession)
            .Where(booking =>
                booking.StudioId == _currentUser.StudioId
                && booking.MemberId == source.MemberId
                && booking.BookingSource == "fixed_schedule"
                && (booking.Status == BookingStatuses.Booked
                    || booking.Status == BookingStatuses.Waitlisted)
                && booking.ClassSession.RecurringScheduleId == source.RecurringScheduleId
                && booking.ClassSession.StartsAt >= now)
            .ToListAsync();

        foreach (var booking in sourceBookings)
        {
            booking.Status = BookingStatuses.Cancelled;
            booking.CancelledAt = now;
            booking.CancellationReason = "fixed_assignment";
            booking.UpdatedAt = now;
        }

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync();
            return ServiceResult.Conflict(
                "Fixed schedule cannot be moved.",
                "The target recurring schedule changed while the member was being moved.");
        }

        foreach (var session in target.ClassSessions
            .Where(item => item.Status == ClassSessionStatuses.Scheduled)
            .OrderBy(item => item.StartsAt))
        {
            var localDate = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(session.StartsAt, timezone));
            if (localDate < today
                || (targetEndsOn.HasValue && localDate > targetEndsOn.Value))
            {
                continue;
            }

            var existingBooking = session.Bookings.FirstOrDefault(item => item.MemberId == source.MemberId);
            if (existingBooking is not null
                && existingBooking.Status != BookingStatuses.Cancelled)
            {
                continue;
            }

            if (existingBooking is not null
                && existingBooking.CancellationReason != "fixed_assignment")
            {
                continue;
            }

            var membershipDecision = await _membershipBookingPolicy.EvaluateAsync(
                source.MemberId,
                session.StartsAt,
                existingBooking?.Id);
            if (!membershipDecision.IsAllowed)
            {
                continue;
            }

            var occupied = session.Bookings.Count(item =>
                item.MemberId != source.MemberId
                && BookingStatuses.CapacityCounting.Contains(item.Status));
            var bookingStatus = occupied < session.Capacity
                ? BookingStatuses.Booked
                : BookingStatuses.Waitlisted;

            if (existingBooking is null)
            {
                session.Bookings.Add(new Booking
                {
                    StudioId = _currentUser.StudioId,
                    MemberId = source.MemberId,
                    BookingSource = "fixed_schedule",
                    Status = bookingStatus,
                    BookedAt = now,
                    CreatedAt = now,
                    UpdatedAt = now
                });
            }
            else
            {
                existingBooking.Status = bookingStatus;
                existingBooking.BookingSource = "fixed_schedule";
                existingBooking.CancelledAt = null;
                existingBooking.CancellationReason = null;
                existingBooking.UpdatedAt = now;
            }
        }

        try
        {
            await _dbContext.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (DbUpdateException)
        {
            await transaction.RollbackAsync();
            return ServiceResult.Conflict(
                "Fixed schedule cannot be moved.",
                "The target recurring schedule changed while the member was being moved.");
        }
        catch (PostgresException exception)
            when (exception.SqlState == PostgresErrorCodes.SerializationFailure)
        {
            await transaction.RollbackAsync();
            return ServiceResult.Conflict(
                "Fixed schedule cannot be moved.",
                "The target recurring schedule changed while the member was being moved.");
        }

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> CancelScheduleAsync(
        long id,
        CancelMemberFixedScheduleRequest request)
    {
        var schedule = await _dbContext.MemberFixedSchedules
            .Include(item => item.RecurringSchedule)
            .FirstOrDefaultAsync(item =>
                item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult.NotFound(
                "Member fixed schedule not found.",
                "A fixed schedule with this id does not exist.");
        }

        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == schedule.RecurringSchedule.TrainerId;

        if (!isAdmin && !isAssignedTrainer)
        {
            return ServiceResult.Forbidden(
                "Fixed schedule cannot be cancelled.",
                "Trainers can cancel only assignments for their own recurring schedules.");
        }

        if (schedule.Status == "cancelled")
        {
            return ServiceResult.Conflict(
                "Fixed schedule is already cancelled.",
                "This fixed schedule assignment has already been cancelled.");
        }

        if (request.EffectiveFrom == default || request.EffectiveFrom < schedule.StartsOn)
        {
            return ServiceResult.Conflict(
                "Invalid cancellation date.",
                "Cancellation date must be on or after the assignment start date.");
        }

        if (schedule.EndsOn.HasValue && request.EffectiveFrom > schedule.EndsOn.Value)
        {
            return ServiceResult.Conflict(
                "Invalid cancellation date.",
                "Cancellation date cannot be after the assignment end date.");
        }

        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var localBoundary = request.EffectiveFrom.ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified);
        var utcBoundary = TimeZoneInfo.ConvertTimeToUtc(localBoundary, timezone);
        var now = DateTime.UtcNow;

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        var bookings = await _dbContext.Bookings
            .Include(booking => booking.ClassSession)
            .Where(booking =>
                booking.StudioId == _currentUser.StudioId
                && booking.MemberId == schedule.MemberId
                && booking.BookingSource == "fixed_schedule"
                && (booking.Status == BookingStatuses.Booked
                    || booking.Status == BookingStatuses.Waitlisted)
                && booking.ClassSession.RecurringScheduleId == schedule.RecurringScheduleId
                && booking.ClassSession.StartsAt >= utcBoundary
                && booking.ClassSession.StartsAt >= now)
            .ToListAsync();

        schedule.Status = "cancelled";
        schedule.EndsOn = request.EffectiveFrom > schedule.StartsOn
            ? request.EffectiveFrom.AddDays(-1)
            : schedule.StartsOn;
        schedule.UpdatedAt = now;

        foreach (var booking in bookings)
        {
            booking.Status = BookingStatuses.Cancelled;
            booking.CancelledAt = now;
            booking.CancellationReason = "fixed_assignment";
            booking.UpdatedAt = now;
        }

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        return ServiceResult.Success();
    }

    private IQueryable<MemberFixedSchedule> QuerySchedules()
    {
        var query = _dbContext.MemberFixedSchedules
            .AsNoTracking()
            .Where(schedule => schedule.StudioId == _currentUser.StudioId);

        if (_currentUser.IsMemberOnly)
        {
            var memberId = _currentUser.MemberId
                ?? throw new InvalidOperationException("Authenticated member is missing the member_id claim.");
            query = query.Where(schedule => schedule.MemberId == memberId);
        }

        return query;
    }

    private ServiceResult? AuthorizeSchedule(RecurringClassSchedule schedule)
    {
        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == schedule.TrainerId;

        return isAdmin || isAssignedTrainer
            ? null
            : ServiceResult.Forbidden(
                "Recurring schedule cannot be changed.",
                "Trainers can change only their own recurring schedules.");
    }

    private static IQueryable<MemberFixedScheduleResponse> Project(IQueryable<MemberFixedSchedule> query)
    {
        return query.Select(schedule => new MemberFixedScheduleResponse(
            schedule.Id,
            schedule.MemberId,
            schedule.Member.FirstName + " " + schedule.Member.LastName,
            schedule.RecurringScheduleId,
            schedule.RecurringSchedule.ClassType.Name,
            schedule.RecurringSchedule.Trainer.FirstName + " " + schedule.RecurringSchedule.Trainer.LastName,
            schedule.RecurringSchedule.DayOfWeek,
            schedule.RecurringSchedule.StartsAtTime,
            schedule.StartsOn,
            schedule.EndsOn,
            schedule.Status));
    }

    private async Task<ServiceResult?> ValidateRequestAsync(CreateMemberFixedScheduleRequest request)
    {
        if (request.EndsOn.HasValue && request.EndsOn.Value < request.StartsOn)
        {
            return ServiceResult.Conflict(
                "Invalid fixed schedule dates.",
                "End date must be on or after start date.");
        }

        if (!AllowedStatuses.Contains(Normalize(request.Status)))
        {
            return ServiceResult.Conflict(
                "Invalid fixed schedule status.",
                "Status must be active, paused or cancelled.");
        }

        if (!await _dbContext.Members.AnyAsync(member =>
            member.Id == request.MemberId && member.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Member does not exist.",
                "Fixed schedule must reference a member from the current studio.");
        }

        var recurringSchedule = await _dbContext.RecurringClassSchedules
            .AsNoTracking()
            .FirstOrDefaultAsync(schedule =>
                schedule.Id == request.RecurringScheduleId
                && schedule.StudioId == _currentUser.StudioId);

        if (recurringSchedule is null)
        {
            return ServiceResult.Conflict(
                "Recurring schedule does not exist.",
                "Fixed schedule must reference a recurring schedule from the current studio.");
        }

        if (request.StartsOn < recurringSchedule.ValidFrom
            || (recurringSchedule.ValidUntil.HasValue
                && request.StartsOn > recurringSchedule.ValidUntil.Value)
            || (request.EndsOn.HasValue && request.EndsOn.Value < recurringSchedule.ValidFrom))
        {
            return ServiceResult.Conflict(
                "Fixed schedule is outside the recurring schedule period.",
                "The assignment period must overlap the recurring schedule period.");
        }

        return null;
    }

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();
}
