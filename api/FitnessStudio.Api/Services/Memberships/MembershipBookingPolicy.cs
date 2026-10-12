using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Memberships;

public sealed class MembershipBookingPolicy : IMembershipBookingPolicy
{
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MembershipBookingPolicy(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public Task AcquireMemberLockAsync(long memberId)
    {
        if (_dbContext.Database.CurrentTransaction is null)
        {
            throw new InvalidOperationException(
                "A database transaction must be active before acquiring a membership booking lock.");
        }

        return _dbContext.Database.ExecuteSqlInterpolatedAsync(
            $"SELECT pg_advisory_xact_lock({memberId})");
    }

    public async Task<MembershipBookingDecision> EvaluateAsync(
        long memberId,
        DateTime classSessionStartsAt,
        long? ignoredBookingId = null)
    {
        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var sessionDate = GetLocalDate(classSessionStartsAt, timezone);

        var membership = await _dbContext.MemberMemberships
            .AsNoTracking()
            .Include(item => item.MembershipPlan)
            .Where(item =>
                item.StudioId == _currentUser.StudioId
                && item.MemberId == memberId
                && item.StartsOn <= sessionDate
                && (!item.EndsOn.HasValue || sessionDate < item.EndsOn.Value))
            .OrderByDescending(item => item.StartsOn)
            .FirstOrDefaultAsync();

        if (membership is null)
        {
            return new MembershipBookingDecision(
                MembershipBookingDecisionStatus.MissingMembership);
        }

        var plan = membership.MembershipPlan;
        if (!plan.SessionLimit.HasValue || plan.SessionLimitPeriod is null)
        {
            return new MembershipBookingDecision(MembershipBookingDecisionStatus.Allowed);
        }

        var period = GetUsagePeriod(
            membership.StartsOn,
            membership.EndsOn,
            plan.SessionLimitPeriod,
            sessionDate);
        var startsAtUtc = ToUtcBoundary(period.StartsOn, timezone);
        var endsAtUtcExclusive = period.EndsOnExclusive.HasValue
            ? ToUtcBoundary(period.EndsOnExclusive.Value, timezone)
            : (DateTime?)null;

        var persistedUsageQuery = _dbContext.Bookings.Where(booking =>
            booking.StudioId == _currentUser.StudioId
            && booking.MemberId == memberId
            && (!ignoredBookingId.HasValue || booking.Id != ignoredBookingId.Value)
            && BookingStatuses.CapacityCounting.Contains(booking.Status)
            && booking.ClassSession.StartsAt >= startsAtUtc
            && (!endsAtUtcExclusive.HasValue
                || booking.ClassSession.StartsAt < endsAtUtcExclusive.Value));
        var persistedUsage = await persistedUsageQuery.CountAsync();
        var latestPersistedUsage = !endsAtUtcExclusive.HasValue
            ? await persistedUsageQuery.MaxAsync(booking => (DateTime?)booking.ClassSession.StartsAt)
            : null;
        var pendingUsage = GetPendingUsage(
            memberId,
            startsAtUtc,
            endsAtUtcExclusive,
            ignoredBookingId);
        var used = persistedUsage + pendingUsage.Count;
        var displayEndsOn = period.EndsOnExclusive?.AddDays(-1)
            ?? GetLatestLocalDate(
                sessionDate,
                timezone,
                latestPersistedUsage,
                pendingUsage.LatestStartsAt);

        return new MembershipBookingDecision(
            Decide(used, plan.SessionLimit),
            period.StartsOn,
            displayEndsOn,
            used,
            plan.SessionLimit.Value);
    }

    internal static (DateOnly StartsOn, DateOnly? EndsOnExclusive) GetUsagePeriod(
        DateOnly membershipStartsOn,
        DateOnly? membershipEndsOn,
        string period,
        DateOnly sessionDate)
    {
        var calculated = period switch
        {
            "week" => GetWeek(sessionDate),
            "month" => GetMonth(sessionDate),
            "membership" => (membershipStartsOn, membershipEndsOn),
            _ => throw new InvalidOperationException(
                $"Unsupported membership limit period '{period}'.")
        };

        var startsOn = calculated.Item1 < membershipStartsOn
            ? membershipStartsOn
            : calculated.Item1;
        var endsOnExclusive = Min(calculated.Item2, membershipEndsOn);
        return (startsOn, endsOnExclusive);
    }

    internal static MembershipBookingDecisionStatus Decide(int used, int? allowed)
    {
        return !allowed.HasValue || used < allowed.Value
            ? MembershipBookingDecisionStatus.Allowed
            : MembershipBookingDecisionStatus.LimitReached;
    }

    internal static DateOnly GetLocalDate(DateTime utcDateTime, TimeZoneInfo timezone)
    {
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, timezone));
    }

    private PendingUsage GetPendingUsage(
        long memberId,
        DateTime startsAtUtc,
        DateTime? endsAtUtcExclusive,
        long? ignoredBookingId)
    {
        var startsAtValues = _dbContext.ChangeTracker.Entries<Booking>()
            .Where(entry =>
                entry.Entity.StudioId == _currentUser.StudioId
                && entry.Entity.MemberId == memberId
                && (!ignoredBookingId.HasValue || entry.Entity.Id != ignoredBookingId.Value)
                && BookingStatuses.CapacityCounting.Contains(entry.Entity.Status)
                && entry.Entity.ClassSession.StartsAt >= startsAtUtc
                && (!endsAtUtcExclusive.HasValue
                    || entry.Entity.ClassSession.StartsAt < endsAtUtcExclusive.Value)
                && (entry.State == EntityState.Added
                    || entry.State == EntityState.Modified
                    && !BookingStatuses.CapacityCounting.Contains(
                        entry.OriginalValues.GetValue<string>(nameof(Booking.Status)))))
            .Select(entry => entry.Entity.ClassSession.StartsAt)
            .ToList();

        return new PendingUsage(
            startsAtValues.Count,
            startsAtValues.Count == 0 ? null : startsAtValues.Max());
    }

    private static DateOnly GetLatestLocalDate(
        DateOnly sessionDate,
        TimeZoneInfo timezone,
        DateTime? latestPersistedUsage,
        DateTime? latestPendingUsage)
    {
        var result = sessionDate;

        if (latestPersistedUsage.HasValue)
        {
            var persistedDate = GetLocalDate(latestPersistedUsage.Value, timezone);
            if (persistedDate > result)
            {
                result = persistedDate;
            }
        }

        if (latestPendingUsage.HasValue)
        {
            var pendingDate = GetLocalDate(latestPendingUsage.Value, timezone);
            if (pendingDate > result)
            {
                result = pendingDate;
            }
        }

        return result;
    }

    private static (DateOnly, DateOnly?) GetWeek(DateOnly date)
    {
        var daysSinceMonday = ((int)date.DayOfWeek + 6) % 7;
        var startsOn = date.AddDays(-daysSinceMonday);
        return (startsOn, startsOn.AddDays(7));
    }

    private static (DateOnly, DateOnly?) GetMonth(DateOnly date)
    {
        var startsOn = new DateOnly(date.Year, date.Month, 1);
        return (startsOn, startsOn.AddMonths(1));
    }

    private static DateOnly? Min(DateOnly? first, DateOnly? second)
    {
        if (!first.HasValue)
        {
            return second;
        }

        if (!second.HasValue)
        {
            return first;
        }

        return first.Value <= second.Value ? first : second;
    }

    private static DateTime ToUtcBoundary(DateOnly date, TimeZoneInfo timezone)
    {
        return TimeZoneInfo.ConvertTimeToUtc(
            date.ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified),
            timezone);
    }

    private sealed record PendingUsage(int Count, DateTime? LatestStartsAt);
}
