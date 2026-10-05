using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MemberFixedSchedules;

public class MemberFixedSchedulesService : IMemberFixedSchedulesService
{
    private static readonly HashSet<string> AllowedStatuses = ["active", "paused", "cancelled"];
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MemberFixedSchedulesService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
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
        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return new ServiceResult<MemberFixedScheduleResponse>(
                validationResult.Status,
                default,
                validationResult.Error);
        }

        var now = DateTime.UtcNow;
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
        }
        catch (DbUpdateException)
        {
            return ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Fixed schedule already exists.",
                "This member already has an active or paused assignment to the recurring schedule.");
        }

        return await GetScheduleAsync(schedule.Id);
    }

    public async Task<ServiceResult> UpdateScheduleAsync(long id, UpdateMemberFixedScheduleRequest request)
    {
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

        schedule.MemberId = request.MemberId;
        schedule.RecurringScheduleId = request.RecurringScheduleId;
        schedule.StartsOn = request.StartsOn;
        schedule.EndsOn = request.EndsOn;
        schedule.Status = Normalize(request.Status);
        schedule.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _dbContext.SaveChangesAsync();
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
