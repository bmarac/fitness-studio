using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Dtos.RecurringClassSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.RecurringClassSchedules;

public class RecurringClassSchedulesService : IRecurringClassSchedulesService
{
    private static readonly HashSet<string> AllowedStatuses = ["active", "inactive"];
    private const int DefaultGenerationWeeksAhead = 4;
    private const int MaximumGenerationWeeksAhead = 52;
    private readonly ICurrentUserContext _currentUser;
    private readonly IClassSessionsService _classSessionsService;
    private readonly FitnessStudioDbContext _dbContext;

    public RecurringClassSchedulesService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser,
        IClassSessionsService classSessionsService)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _classSessionsService = classSessionsService;
    }

    public Task<List<RecurringClassScheduleResponse>> GetSchedulesAsync()
    {
        return Project(QuerySchedules())
            .OrderBy(schedule => schedule.DayOfWeek)
            .ThenBy(schedule => schedule.StartsAtTime)
            .ToListAsync();
    }

    public async Task<ServiceResult<RecurringClassScheduleResponse>> GetScheduleAsync(long id)
    {
        var schedule = await Project(QuerySchedules().Where(item => item.Id == id)).FirstOrDefaultAsync();

        return schedule is null
            ? ServiceResult<RecurringClassScheduleResponse>.NotFound(
                "Recurring class schedule not found.",
                "A recurring schedule with this id does not exist.")
            : ServiceResult<RecurringClassScheduleResponse>.Success(schedule);
    }

    public async Task<ServiceResult<RecurringClassScheduleResponse>> CreateScheduleAsync(
        CreateRecurringClassScheduleRequest request)
    {
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
            Status = Normalize(request.Status),
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
        schedule.Status = Normalize(request.Status);
        schedule.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
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

    private IQueryable<RecurringClassSchedule> QuerySchedules()
    {
        return _dbContext.RecurringClassSchedules
            .AsNoTracking()
            .Where(schedule => schedule.StudioId == _currentUser.StudioId);
    }

    private static IQueryable<RecurringClassScheduleResponse> Project(IQueryable<RecurringClassSchedule> query)
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
            schedule.Status));
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

        if (!AllowedStatuses.Contains(Normalize(request.Status)))
        {
            return ServiceResult.Conflict(
                "Invalid recurring schedule status.",
                "Status must be active or inactive.");
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

        if (Normalize(request.Status) == "active")
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

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();
}
