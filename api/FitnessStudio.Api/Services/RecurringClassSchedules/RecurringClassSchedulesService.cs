using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Dtos.RecurringClassSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MemberFixedSchedules;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.RecurringClassSchedules;

public class RecurringClassSchedulesService : IRecurringClassSchedulesService
{
    private static readonly HashSet<string> AllowedStatuses = ["active", "paused", "ended"];
    private const int DefaultGenerationWeeksAhead = 4;
    private const int MaximumGenerationWeeksAhead = 52;
    private readonly ICurrentUserContext _currentUser;
    private readonly IClassSessionsService _classSessionsService;
    private readonly FitnessStudioDbContext _dbContext;
    private readonly IMembershipBookingPolicy _membershipBookingPolicy;

    public RecurringClassSchedulesService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser,
        IClassSessionsService classSessionsService,
        IMembershipBookingPolicy membershipBookingPolicy)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _classSessionsService = classSessionsService;
        _membershipBookingPolicy = membershipBookingPolicy;
    }

    public async Task<List<RecurringClassScheduleResponse>> GetSchedulesAsync()
    {
        var (_, today) = await GetStudioDateContextAsync();

        return await Project(QuerySchedules()
            .OrderBy(schedule => schedule.DayOfWeek)
            .ThenBy(schedule => schedule.StartsAtTime), today)
            .ToListAsync();
    }

    public async Task<ServiceResult<RecurringClassScheduleResponse>> GetScheduleAsync(long id)
    {
        var (_, today) = await GetStudioDateContextAsync();
        var schedule = await Project(
                QuerySchedules().Where(item => item.Id == id),
                today)
            .FirstOrDefaultAsync();

        return schedule is null
            ? ServiceResult<RecurringClassScheduleResponse>.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.")
            : ServiceResult<RecurringClassScheduleResponse>.Success(schedule);
    }

    public async Task<ServiceResult<List<MemberFixedScheduleResponse>>> GetScheduleMembersAsync(long id)
    {
        var schedule = await _dbContext.RecurringClassSchedules
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult<List<MemberFixedScheduleResponse>>.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.");
        }

        var authorization = AuthorizeScheduleManagement(schedule);
        if (authorization is not null)
        {
            return new ServiceResult<List<MemberFixedScheduleResponse>>(
                authorization.Status,
                default,
                authorization.Error);
        }

        var (_, today) = await GetStudioDateContextAsync();
        var members = await _dbContext.MemberFixedSchedules
            .AsNoTracking()
            .Where(item =>
                item.StudioId == _currentUser.StudioId
                && item.RecurringScheduleId == id
                && item.Status == "active"
                && item.StartsOn <= today
                && (!item.EndsOn.HasValue || item.EndsOn.Value >= today))
            .OrderBy(item => item.Member.LastName)
            .ThenBy(item => item.Member.FirstName)
            .Select(item => new MemberFixedScheduleResponse(
                item.Id,
                item.MemberId,
                item.Member.FirstName + " " + item.Member.LastName,
                item.RecurringScheduleId,
                item.RecurringSchedule.ClassType.Name,
                item.RecurringSchedule.Trainer.FirstName + " " + item.RecurringSchedule.Trainer.LastName,
                item.RecurringSchedule.DayOfWeek,
                item.RecurringSchedule.StartsAtTime,
                item.StartsOn,
                item.EndsOn,
                item.Status))
            .ToListAsync();

        return ServiceResult<List<MemberFixedScheduleResponse>>.Success(members);
    }

    public async Task<ServiceResult<List<AvailableFixedScheduleMemberResponse>>> GetAvailableMembersAsync(
        long id,
        DateOnly startsOn)
    {
        var schedule = await _dbContext.RecurringClassSchedules
            .AsNoTracking()
            .FirstOrDefaultAsync(item => item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult<List<AvailableFixedScheduleMemberResponse>>.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.");
        }

        if (schedule.Status != "active"
            || startsOn < schedule.ValidFrom
            || (schedule.ValidUntil.HasValue && startsOn > schedule.ValidUntil.Value))
        {
            return ServiceResult<List<AvailableFixedScheduleMemberResponse>>.Conflict(
                "Recurring schedule is unavailable.",
                "Members can be assigned only while the recurring schedule is active.");
        }

        var members = await FixedSchedulePackagePolicy.GetAvailableMembersAsync(
            _dbContext,
            _currentUser.StudioId,
            id,
            startsOn,
            schedule.ValidUntil);
        return ServiceResult<List<AvailableFixedScheduleMemberResponse>>.Success(members);
    }

    public async Task<ServiceResult<RecurringClassScheduleResponse>> CreateScheduleAsync(
        CreateRecurringClassScheduleRequest request)
    {
        var authorization = AuthorizeScheduleCreation(_currentUser, request.TrainerId);
        if (authorization is not null)
        {
            return new ServiceResult<RecurringClassScheduleResponse>(
                authorization.Status,
                default,
                authorization.Error);
        }

        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return new ServiceResult<RecurringClassScheduleResponse>(
                validationResult.Status,
                default,
                validationResult.Error);
        }

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        var now = DateTime.UtcNow;
        var schedule = new RecurringClassSchedule
        {
            StudioId = _currentUser.StudioId,
            ClassTypeId = request.ClassTypeId,
            TrainerId = request.TrainerId,
            DayOfWeek = request.DayOfWeek,
            StartsAtTime = request.StartsAtTime,
            DurationMinutes = request.DurationMinutes,
            Capacity = request.Capacity,
            ValidFrom = request.ValidFrom,
            ValidUntil = request.ValidUntil,
            Status = NormalizeStatus(request.Status),
            StatusEffectiveFrom = NormalizeStatus(request.Status) == "active"
                ? null
                : request.ValidFrom,
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.RecurringClassSchedules.Add(schedule);
        await _dbContext.SaveChangesAsync();

        if (schedule.Status == "active")
        {
            var generationResult = await GenerateClassSessionsAsync(schedule);
            if (generationResult.Status != ServiceResultStatus.Success)
            {
                await transaction.RollbackAsync();
                return new ServiceResult<RecurringClassScheduleResponse>(
                    generationResult.Status,
                    default,
                    generationResult.Error);
            }
        }

        await transaction.CommitAsync();

        return await GetScheduleAsync(schedule.Id);
    }

    internal static ServiceResult? AuthorizeScheduleCreation(
        ICurrentUserContext currentUser,
        long requestedTrainerId)
    {
        if (currentUser.IsInRole(AuthRoles.Admin))
        {
            return null;
        }

        if (currentUser.IsInRole(AuthRoles.Trainer)
            && currentUser.TrainerId == requestedTrainerId)
        {
            return null;
        }

        return ServiceResult.Forbidden(
            "Recurring schedule cannot be created.",
            "Trainers can create recurring schedules only for themselves.");
    }

    public async Task<ServiceResult> UpdateScheduleAsync(long id, UpdateRecurringClassScheduleRequest request)
    {
        var schedule = await _dbContext.RecurringClassSchedules.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.");
        }

        if (NormalizeStatus(request.Status) != schedule.Status)
        {
            return ServiceResult.Conflict(
                "Recurring schedule status cannot be updated here.",
                "Use the pause, resume or end operation to change schedule status.");
        }

        var validationResult = await ValidateRequestAsync(request, id);
        if (validationResult is not null)
        {
            return validationResult;
        }

        schedule.ClassTypeId = request.ClassTypeId;
        schedule.TrainerId = request.TrainerId;
        schedule.DayOfWeek = request.DayOfWeek;
        schedule.StartsAtTime = request.StartsAtTime;
        schedule.DurationMinutes = request.DurationMinutes;
        schedule.Capacity = request.Capacity;
        schedule.ValidFrom = request.ValidFrom;
        schedule.ValidUntil = request.ValidUntil;
        schedule.Status = NormalizeStatus(request.Status);
        schedule.StatusEffectiveFrom = schedule.Status == "active"
            ? null
            : request.ValidFrom;
        schedule.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> PauseScheduleAsync(
        long id,
        ChangeRecurringClassScheduleStatusRequest request)
    {
        var schedule = await LoadScheduleForLifecycleAsync(id);
        if (schedule is null)
        {
            return ScheduleNotFound();
        }

        var authorization = AuthorizeScheduleManagement(schedule);
        if (authorization is not null)
        {
            return authorization;
        }

        if (schedule.Status != "active")
        {
            return ServiceResult.Conflict(
                "Recurring schedule cannot be paused.",
                "Only an active recurring schedule can be paused.");
        }

        var (timeZone, today) = await GetStudioDateContextAsync();
        var dateValidation = ValidateEffectiveDate(schedule, request.EffectiveFrom, today);
        if (dateValidation is not null)
        {
            return dateValidation;
        }

        var boundary = ToUtcBoundary(request.EffectiveFrom, timeZone);
        var now = DateTime.UtcNow;

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        schedule.Status = "paused";
        schedule.StatusEffectiveFrom = request.EffectiveFrom;
        schedule.UpdatedAt = now;
        CancelScheduledSessions(schedule, boundary, now, "schedule_paused");

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> ResumeScheduleAsync(
        long id,
        ChangeRecurringClassScheduleStatusRequest request)
    {
        var schedule = await LoadScheduleForLifecycleAsync(id);
        if (schedule is null)
        {
            return ScheduleNotFound();
        }

        var authorization = AuthorizeScheduleManagement(schedule);
        if (authorization is not null)
        {
            return authorization;
        }

        if (schedule.Status != "paused")
        {
            return ServiceResult.Conflict(
                "Recurring schedule cannot be resumed.",
                "Only a paused recurring schedule can be resumed.");
        }

        var (timeZone, today) = await GetStudioDateContextAsync();
        var dateValidation = ValidateEffectiveDate(schedule, request.EffectiveFrom, today);
        if (dateValidation is not null)
        {
            return dateValidation;
        }

        if (schedule.StatusEffectiveFrom.HasValue
            && request.EffectiveFrom < schedule.StatusEffectiveFrom.Value)
        {
            return ServiceResult.Conflict(
                "Invalid resume date.",
                "Resume date cannot be before the pause date.");
        }

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        var now = DateTime.UtcNow;
        var generationEnd = await GetGenerationEndAsync(schedule, today);
        var generationStart = request.EffectiveFrom > today ? request.EffectiveFrom : today;
        if (generationStart < schedule.ValidFrom)
        {
            generationStart = schedule.ValidFrom;
        }

        var sessionsByStart = schedule.ClassSessions.ToDictionary(item => item.StartsAt);
        var sessionsToBook = new List<ClassSession>();

        for (var date = generationStart; date <= generationEnd; date = date.AddDays(1))
        {
            if (ToIsoDayOfWeek(date) != schedule.DayOfWeek)
            {
                continue;
            }

            var startsAt = ToUtcStart(date, schedule.StartsAtTime, timeZone);
            if (sessionsByStart.TryGetValue(startsAt, out var existingSession))
            {
                if (existingSession.Status == ClassSessionStatuses.Cancelled
                    && existingSession.CancellationReason == "schedule_paused")
                {
                    existingSession.Status = ClassSessionStatuses.Scheduled;
                    existingSession.CancellationReason = null;
                    existingSession.UpdatedAt = now;
                    sessionsToBook.Add(existingSession);
                }

                continue;
            }

            var session = new ClassSession
            {
                StudioId = schedule.StudioId,
                ClassTypeId = schedule.ClassTypeId,
                TrainerId = schedule.TrainerId,
                RecurringScheduleId = schedule.Id,
                StartsAt = startsAt,
                EndsAt = startsAt.AddMinutes(schedule.DurationMinutes),
                Capacity = schedule.Capacity,
                Status = ClassSessionStatuses.Scheduled,
                CreatedAt = now,
                UpdatedAt = now
            };
            schedule.ClassSessions.Add(session);
            sessionsToBook.Add(session);
        }

        await RestoreFixedScheduleBookingsAsync(schedule, sessionsToBook, timeZone, now);
        schedule.Status = "active";
        schedule.StatusEffectiveFrom = null;
        schedule.UpdatedAt = now;

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> EndScheduleAsync(
        long id,
        ChangeRecurringClassScheduleStatusRequest request)
    {
        var schedule = await LoadScheduleForLifecycleAsync(id);
        if (schedule is null)
        {
            return ScheduleNotFound();
        }

        var authorization = AuthorizeScheduleManagement(schedule);
        if (authorization is not null)
        {
            return authorization;
        }

        if (schedule.Status == "ended")
        {
            return ServiceResult.Conflict(
                "Recurring schedule is already ended.",
                "An ended recurring schedule cannot be changed.");
        }

        var (timeZone, today) = await GetStudioDateContextAsync();
        var dateValidation = ValidateEffectiveDate(schedule, request.EffectiveFrom, today);
        if (dateValidation is not null)
        {
            return dateValidation;
        }

        var boundary = ToUtcBoundary(request.EffectiveFrom, timeZone);
        var now = DateTime.UtcNow;

        await using var transaction = await _dbContext.Database.BeginTransactionAsync();

        schedule.Status = "ended";
        schedule.StatusEffectiveFrom = request.EffectiveFrom;
        schedule.ValidUntil = request.EffectiveFrom > schedule.ValidFrom
            ? request.EffectiveFrom.AddDays(-1)
            : schedule.ValidFrom;
        schedule.UpdatedAt = now;
        CancelScheduledSessions(schedule, boundary, now, "schedule_ended", includePaused: true);

        foreach (var assignment in schedule.MemberFixedSchedules.Where(item =>
            (item.Status == "active" || item.Status == "paused")
            && (!item.EndsOn.HasValue || item.EndsOn.Value >= request.EffectiveFrom)))
        {
            assignment.Status = "cancelled";
            assignment.EndsOn = request.EffectiveFrom > assignment.StartsOn
                ? request.EffectiveFrom.AddDays(-1)
                : assignment.StartsOn;
            assignment.UpdatedAt = now;
        }

        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteScheduleAsync(long id)
    {
        var schedule = await _dbContext.RecurringClassSchedules.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (schedule is null)
        {
            return ServiceResult.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.");
        }

        _dbContext.RecurringClassSchedules.Remove(schedule);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Recurring class schedule cannot be deleted.",
                "The schedule cannot be deleted because class sessions or fixed assignments reference it.");
        }

        return ServiceResult.Success();
    }

    private Task<RecurringClassSchedule?> LoadScheduleForLifecycleAsync(long id)
    {
        return _dbContext.RecurringClassSchedules
            .Include(item => item.ClassSessions)
                .ThenInclude(item => item.Bookings)
            .Include(item => item.MemberFixedSchedules)
            .FirstOrDefaultAsync(item =>
                item.Id == id && item.StudioId == _currentUser.StudioId);
    }

    private ServiceResult? AuthorizeScheduleManagement(RecurringClassSchedule schedule)
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

    private static ServiceResult? ValidateEffectiveDate(
        RecurringClassSchedule schedule,
        DateOnly effectiveFrom,
        DateOnly today)
    {
        if (effectiveFrom == default || effectiveFrom < today)
        {
            return ServiceResult.Conflict(
                "Invalid effective date.",
                "Effective date must be today or a future date.");
        }

        if (effectiveFrom < schedule.ValidFrom)
        {
            return ServiceResult.Conflict(
                "Invalid effective date.",
                "Effective date cannot be before the recurring schedule start date.");
        }

        if (schedule.ValidUntil.HasValue && effectiveFrom > schedule.ValidUntil.Value)
        {
            return ServiceResult.Conflict(
                "Invalid effective date.",
                "Effective date cannot be after the recurring schedule end date.");
        }

        return null;
    }

    private async Task<(TimeZoneInfo TimeZone, DateOnly Today)> GetStudioDateContextAsync()
    {
        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timeZone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone));
        return (timeZone, today);
    }

    private async Task<DateOnly> GetGenerationEndAsync(
        RecurringClassSchedule schedule,
        DateOnly today)
    {
        var configuredValue = await _dbContext.StudioSettings
            .AsNoTracking()
            .Where(setting =>
                setting.StudioId == schedule.StudioId
                && setting.Setting == "class_session_generation_weeks_ahead")
            .Select(setting => setting.Value)
            .FirstOrDefaultAsync();
        var weeksAhead = int.TryParse(configuredValue, out var parsedWeeks)
            && parsedWeeks is >= 1 and <= MaximumGenerationWeeksAhead
                ? parsedWeeks
                : DefaultGenerationWeeksAhead;
        var currentWeekStart = today.AddDays(-ToIsoDayOfWeek(today) + 1);
        var generationEnd = currentWeekStart.AddDays(weeksAhead * 7 + 6);

        if (schedule.ValidUntil.HasValue && schedule.ValidUntil.Value < generationEnd)
        {
            generationEnd = schedule.ValidUntil.Value;
        }

        return generationEnd;
    }

    private static DateTime ToUtcBoundary(DateOnly date, TimeZoneInfo timeZone)
    {
        var localBoundary = date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(localBoundary, timeZone);
    }

    private static DateTime ToUtcStart(
        DateOnly date,
        TimeOnly startsAt,
        TimeZoneInfo timeZone)
    {
        var localStartsAt = DateTime.SpecifyKind(
            date.ToDateTime(startsAt),
            DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(localStartsAt, timeZone);
    }

    internal static void CancelScheduledSessions(
        RecurringClassSchedule schedule,
        DateTime boundary,
        DateTime now,
        string reason,
        bool includePaused = false)
    {
        foreach (var session in schedule.ClassSessions.Where(item =>
            item.StartsAt >= boundary
            && (item.Status == ClassSessionStatuses.Scheduled
                || (includePaused
                    && item.Status == ClassSessionStatuses.Cancelled
                    && item.CancellationReason == "schedule_paused"))))
        {
            session.Status = ClassSessionStatuses.Cancelled;
            session.CancellationReason = reason;
            session.UpdatedAt = now;

            foreach (var booking in session.Bookings.Where(item =>
                (item.Status == BookingStatuses.Booked
                    || item.Status == BookingStatuses.Waitlisted)
                || (includePaused
                    && item.Status == BookingStatuses.Cancelled
                    && item.CancellationReason == "schedule_paused")))
            {
                booking.Status = BookingStatuses.Cancelled;
                booking.CancelledAt ??= now;
                booking.CancellationReason = reason;
                booking.UpdatedAt = now;
            }
        }
    }

    private async Task RestoreFixedScheduleBookingsAsync(
        RecurringClassSchedule schedule,
        IEnumerable<ClassSession> sessions,
        TimeZoneInfo timeZone,
        DateTime now)
    {
        var activeAssignments = schedule.MemberFixedSchedules
            .Where(item => item.Status == "active")
            .OrderBy(item => item.CreatedAt)
            .ToList();

        foreach (var memberId in activeAssignments
            .Select(item => item.MemberId)
            .Distinct()
            .OrderBy(id => id))
        {
            await _membershipBookingPolicy.AcquireMemberLockAsync(memberId);
        }

        foreach (var session in sessions.OrderBy(item => item.StartsAt))
        {
            var localStart = TimeZoneInfo.ConvertTimeFromUtc(session.StartsAt, timeZone);
            var sessionDate = DateOnly.FromDateTime(localStart);
            var occupied = session.Bookings.Count(item =>
                BookingStatuses.CapacityCounting.Contains(item.Status));

            foreach (var assignment in activeAssignments.Where(item =>
                item.StartsOn <= sessionDate
                && (!item.EndsOn.HasValue || item.EndsOn.Value >= sessionDate)))
            {
                var existingBooking = session.Bookings
                    .FirstOrDefault(item => item.MemberId == assignment.MemberId);
                var membershipDecision = await _membershipBookingPolicy.EvaluateAsync(
                    assignment.MemberId,
                    session.StartsAt,
                    existingBooking?.Id);

                if (!membershipDecision.IsAllowed)
                {
                    continue;
                }

                var restoredStatus = occupied < session.Capacity
                    ? BookingStatuses.Booked
                    : BookingStatuses.Waitlisted;

                if (existingBooking is not null)
                {
                    if (CanRestoreFixedBooking(existingBooking))
                    {
                        existingBooking.Status = restoredStatus;
                        existingBooking.CancelledAt = null;
                        existingBooking.CancellationReason = null;
                        existingBooking.UpdatedAt = now;
                        if (restoredStatus == BookingStatuses.Booked)
                        {
                            occupied++;
                        }
                    }

                    continue;
                }

                session.Bookings.Add(new Booking
                {
                    StudioId = schedule.StudioId,
                    MemberId = assignment.MemberId,
                    BookingSource = "fixed_schedule",
                    Status = restoredStatus,
                    BookedAt = now,
                    CreatedAt = now,
                    UpdatedAt = now
                });
                if (restoredStatus == BookingStatuses.Booked)
                {
                    occupied++;
                }
            }
        }
    }

    internal static bool CanRestoreFixedBooking(Booking booking)
    {
        return booking.Status == BookingStatuses.Cancelled
            && booking.BookingSource == "fixed_schedule"
            && booking.CancellationReason == "schedule_paused";
    }

    private static ServiceResult ScheduleNotFound()
    {
        return ServiceResult.NotFound(
            "Recurring class schedule not found.",
            "A recurring schedule with this id does not exist.");
    }

    private IQueryable<RecurringClassSchedule> QuerySchedules()
    {
        var query = _dbContext.RecurringClassSchedules
            .AsNoTracking()
            .Where(schedule => schedule.StudioId == _currentUser.StudioId);

        if (!_currentUser.IsInRole(AuthRoles.Admin)
            && _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId.HasValue)
        {
            query = query.Where(schedule => schedule.TrainerId == _currentUser.TrainerId.Value);
        }

        return query;
    }

    private static IQueryable<RecurringClassScheduleResponse> Project(
        IQueryable<RecurringClassSchedule> query,
        DateOnly today)
    {
        return query.Select(schedule => new RecurringClassScheduleResponse(
            schedule.Id,
            schedule.ClassTypeId,
            schedule.ClassType.Name,
            schedule.TrainerId,
            schedule.Trainer.FirstName + " " + schedule.Trainer.LastName,
            schedule.DayOfWeek,
            schedule.StartsAtTime,
            schedule.DurationMinutes,
            schedule.Capacity,
            schedule.ValidFrom,
            schedule.ValidUntil,
            schedule.Status,
            schedule.StatusEffectiveFrom,
            schedule.MemberFixedSchedules.Count(assignment =>
                assignment.Status == "active"
                && assignment.StartsOn <= today
                && (!assignment.EndsOn.HasValue || assignment.EndsOn.Value >= today))));
    }

    private async Task<ServiceResult?> ValidateRequestAsync(
        CreateRecurringClassScheduleRequest request,
        long? ignoredScheduleId = null)
    {
        if (request.ValidUntil.HasValue && request.ValidUntil.Value < request.ValidFrom)
        {
            return ServiceResult.Conflict(
                "Invalid recurring schedule dates.",
                "Valid until must be on or after valid from.");
        }

        if (!AllowedStatuses.Contains(NormalizeStatus(request.Status)))
        {
            return ServiceResult.Conflict(
                "Invalid recurring schedule status.",
                "Status must be active, paused or ended.");
        }

        if (!await _dbContext.ClassTypes.AnyAsync(classType =>
            classType.Id == request.ClassTypeId && classType.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Class type does not exist.",
                "Recurring schedule must reference a class type from the current studio.");
        }

        if (!await _dbContext.Trainers.AnyAsync(trainer =>
            trainer.Id == request.TrainerId && trainer.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Trainer does not exist.",
                "Recurring schedule must reference a trainer from the current studio.");
        }

        if (NormalizeStatus(request.Status) == "active")
        {
            var trainerSchedules = await QuerySchedules()
                .Where(schedule =>
                    schedule.TrainerId == request.TrainerId
                    && schedule.Status == "active"
                    && (!ignoredScheduleId.HasValue || schedule.Id != ignoredScheduleId.Value))
                .ToListAsync();

            var hasOverlap = trainerSchedules.Any(schedule =>
                DateRangesOverlap(
                    request.ValidFrom,
                    request.ValidUntil,
                    schedule.ValidFrom,
                    schedule.ValidUntil)
                && WeeklyTimesOverlap(
                    request.DayOfWeek,
                    request.StartsAtTime,
                    request.DurationMinutes,
                    schedule.DayOfWeek,
                    schedule.StartsAtTime,
                    schedule.DurationMinutes));

            if (hasOverlap)
            {
                return ServiceResult.Conflict(
                    "Trainer schedule overlaps.",
                    "The trainer already has an active recurring class during this time.");
            }
        }

        return null;
    }

    private static bool DateRangesOverlap(
        DateOnly firstStart,
        DateOnly? firstEnd,
        DateOnly secondStart,
        DateOnly? secondEnd)
    {
        return (!firstEnd.HasValue || secondStart <= firstEnd.Value)
            && (!secondEnd.HasValue || firstStart <= secondEnd.Value);
    }

    private static bool WeeklyTimesOverlap(
        short firstDay,
        TimeOnly firstTime,
        int firstDurationMinutes,
        short secondDay,
        TimeOnly secondTime,
        int secondDurationMinutes)
    {
        const int minutesPerDay = 24 * 60;
        const int minutesPerWeek = 7 * minutesPerDay;

        var firstStart = (firstDay - 1) * minutesPerDay + firstTime.Hour * 60 + firstTime.Minute;
        var firstEnd = firstStart + firstDurationMinutes;
        var secondStart = (secondDay - 1) * minutesPerDay + secondTime.Hour * 60 + secondTime.Minute;
        var secondEnd = secondStart + secondDurationMinutes;

        return new[] { -minutesPerWeek, 0, minutesPerWeek }.Any(offset =>
            firstStart < secondEnd + offset && firstEnd > secondStart + offset);
    }

    private async Task<ServiceResult> GenerateClassSessionsAsync(RecurringClassSchedule schedule)
    {
        var studio = await _dbContext.Studios
            .AsNoTracking()
            .Where(studio => studio.Id == schedule.StudioId)
            .Select(studio => new { studio.Timezone })
            .FirstAsync();
        var configuredValue = await _dbContext.StudioSettings
            .AsNoTracking()
            .Where(setting =>
                setting.StudioId == schedule.StudioId
                && setting.Setting == "class_session_generation_weeks_ahead")
            .Select(setting => setting.Value)
            .FirstOrDefaultAsync();
        var weeksAhead = int.TryParse(configuredValue, out var parsedWeeks)
            && parsedWeeks is >= 1 and <= MaximumGenerationWeeksAhead
                ? parsedWeeks
                : DefaultGenerationWeeksAhead;

        var timeZone = TimeZoneInfo.FindSystemTimeZoneById(studio.Timezone);
        var localToday = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone));
        var currentWeekStart = localToday.AddDays(-ToIsoDayOfWeek(localToday) + 1);
        var generationEnd = currentWeekStart.AddDays(weeksAhead * 7 + 6);

        if (schedule.ValidUntil.HasValue && schedule.ValidUntil.Value < generationEnd)
        {
            generationEnd = schedule.ValidUntil.Value;
        }

        var generationStart = schedule.ValidFrom > localToday
            ? schedule.ValidFrom
            : localToday;

        for (var date = generationStart; date <= generationEnd; date = date.AddDays(1))
        {
            if (ToIsoDayOfWeek(date) != schedule.DayOfWeek)
            {
                continue;
            }

            var localStartsAt = DateTime.SpecifyKind(
                date.ToDateTime(schedule.StartsAtTime),
                DateTimeKind.Unspecified);
            var startsAt = TimeZoneInfo.ConvertTimeToUtc(localStartsAt, timeZone);
            var result = await _classSessionsService.CreateClassSessionAsync(
                new CreateClassSessionRequest
                {
                    ClassTypeId = schedule.ClassTypeId,
                    TrainerId = schedule.TrainerId,
                    RecurringScheduleId = schedule.Id,
                    StartsAt = startsAt,
                    EndsAt = startsAt.AddMinutes(schedule.DurationMinutes),
                    Capacity = schedule.Capacity,
                    Status = ClassSessionStatuses.Scheduled
                });

            if (result.Status != ServiceResultStatus.Success)
            {
                return new ServiceResult(result.Status, result.Error);
            }
        }

        return ServiceResult.Success();
    }

    private static int ToIsoDayOfWeek(DateOnly date)
    {
        return date.DayOfWeek == DayOfWeek.Sunday ? 7 : (int)date.DayOfWeek;
    }

    private static string NormalizeStatus(string value)
    {
        var normalized = value.Trim().ToLowerInvariant();
        return normalized == "inactive" ? "paused" : normalized;
    }
}
