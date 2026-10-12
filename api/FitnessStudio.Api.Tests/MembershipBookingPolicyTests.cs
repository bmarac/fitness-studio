using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Services.Memberships;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipBookingPolicyTests
{
    [Theory]
    [InlineData(0, 1, MembershipBookingDecisionStatus.Allowed)]
    [InlineData(1, 1, MembershipBookingDecisionStatus.LimitReached)]
    [InlineData(1, 2, MembershipBookingDecisionStatus.Allowed)]
    [InlineData(2, 2, MembershipBookingDecisionStatus.LimitReached)]
    [InlineData(2, 3, MembershipBookingDecisionStatus.Allowed)]
    [InlineData(3, 3, MembershipBookingDecisionStatus.LimitReached)]
    public void Decide_EnforcesConfiguredLimit(
        int used,
        int allowed,
        MembershipBookingDecisionStatus expected)
    {
        Assert.Equal(expected, MembershipBookingPolicy.Decide(used, allowed));
    }

    [Fact]
    public void Decide_AllowsUnlimitedPlan()
    {
        Assert.Equal(
            MembershipBookingDecisionStatus.Allowed,
            MembershipBookingPolicy.Decide(100, null));
    }

    [Fact]
    public void WeekPeriod_UsesMondayBoundaryAndClipsToMembership()
    {
        var period = MembershipBookingPolicy.GetUsagePeriod(
            new DateOnly(2026, 10, 7),
            new DateOnly(2026, 10, 11),
            "week",
            new DateOnly(2026, 10, 8));

        Assert.Equal(new DateOnly(2026, 10, 7), period.StartsOn);
        Assert.Equal(new DateOnly(2026, 10, 11), period.EndsOnExclusive);
    }

    [Fact]
    public void MonthPeriod_UsesCalendarMonth()
    {
        var period = MembershipBookingPolicy.GetUsagePeriod(
            new DateOnly(2026, 1, 1),
            null,
            "month",
            new DateOnly(2026, 10, 11));

        Assert.Equal(new DateOnly(2026, 10, 1), period.StartsOn);
        Assert.Equal(new DateOnly(2026, 11, 1), period.EndsOnExclusive);
    }

    [Fact]
    public void OpenMembershipPeriod_HasNoUpperBoundary()
    {
        var period = MembershipBookingPolicy.GetUsagePeriod(
            new DateOnly(2026, 10, 1),
            null,
            "membership",
            new DateOnly(2026, 12, 1));

        Assert.Equal(new DateOnly(2026, 10, 1), period.StartsOn);
        Assert.Null(period.EndsOnExclusive);
    }

    [Fact]
    public void LocalDate_UsesStudioTimezone()
    {
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var localDate = MembershipBookingPolicy.GetLocalDate(
            new DateTime(2026, 10, 10, 22, 30, 0, DateTimeKind.Utc),
            timezone);

        Assert.Equal(new DateOnly(2026, 10, 11), localDate);
    }

    [Fact]
    public void UsageStatuses_ExcludeCancelledAndWaitlisted()
    {
        Assert.Contains(BookingStatuses.Booked, BookingStatuses.CapacityCounting);
        Assert.Contains(BookingStatuses.Attended, BookingStatuses.CapacityCounting);
        Assert.Contains(BookingStatuses.NoShow, BookingStatuses.CapacityCounting);
        Assert.DoesNotContain(BookingStatuses.Cancelled, BookingStatuses.CapacityCounting);
        Assert.DoesNotContain(BookingStatuses.Waitlisted, BookingStatuses.CapacityCounting);
    }
}
