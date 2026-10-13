using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MembershipPayments;
using FitnessStudio.Api.Services.Memberships;
using Microsoft.EntityFrameworkCore;
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
    public void BillingCycle_UsesOriginalAnchorAcrossShortMonths()
    {
        var period = MembershipCycle.FindContainingPeriod(
            new DateOnly(2026, 1, 31),
            new DateOnly(2026, 3, 15));

        Assert.Equal(new DateOnly(2026, 2, 28), period?.StartsOn);
        Assert.Equal(new DateOnly(2026, 3, 31), period?.EndsOnExclusive);
    }

    [Theory]
    [InlineData(4, 4)]
    [InlineData(5, 4)]
    [InlineData(6, 5)]
    public void FixedScheduleAllowance_CountsWeekdaysWithoutClassSessions(
        short isoDayOfWeek,
        int expected)
    {
        var count = MembershipBookingPolicy.CountWeekdayOccurrences(
            new DateOnly(2026, 10, 3),
            new DateOnly(2026, 11, 3),
            isoDayOfWeek);

        Assert.Equal(expected, count);
    }

    [Fact]
    public async Task FixedSchedulesReplaceWeeklyLimitAndCancellationOpensMakeupSlot()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixedScheduleMembership(db);
        var statuses = new[]
        {
            BookingStatuses.Booked,
            BookingStatuses.Attended,
            BookingStatuses.NoShow,
            BookingStatuses.Cancelled,
            BookingStatuses.Waitlisted
        };
        for (var index = 0; index < statuses.Length; index++)
        {
            AddBooking(
                db,
                fixture,
                index + 1,
                statuses[index],
                new DateTime(2026, 10, 8 + index, 16, 0, 0, DateTimeKind.Utc));
        }
        await db.SaveChangesAsync();
        var policy = new MembershipBookingPolicy(db, new Context());

        var beforeCancellation = await policy.EvaluateAsync(
            fixture.Member.Id,
            new DateTime(2026, 10, 20, 16, 0, 0, DateTimeKind.Utc));

        Assert.Equal("billing_cycle", beforeCancellation.Period);
        Assert.Equal(new DateOnly(2026, 10, 3), beforeCancellation.PeriodStartsOn);
        Assert.Equal(new DateOnly(2026, 11, 2), beforeCancellation.PeriodEndsOn);
        Assert.Equal(8, beforeCancellation.Allowed);
        Assert.Equal(3, beforeCancellation.Used);

        db.Bookings.Single(item => item.Status == BookingStatuses.Booked).Status =
            BookingStatuses.Cancelled;
        await db.SaveChangesAsync();

        var afterCancellation = await policy.EvaluateAsync(
            fixture.Member.Id,
            new DateTime(2026, 10, 20, 16, 0, 0, DateTimeKind.Utc));

        Assert.Equal(8, afterCancellation.Allowed);
        Assert.Equal(2, afterCancellation.Used);
    }

    [Fact]
    public async Task FullBillingCycleRejectsBookingUntilOneReservationIsCancelled()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixedScheduleMembership(db);
        for (var index = 0; index < 8; index++)
        {
            AddBooking(
                db,
                fixture,
                index + 1,
                BookingStatuses.Booked,
                new DateTime(2026, 10, 4 + index, 16, 0, 0, DateTimeKind.Utc));
        }
        await db.SaveChangesAsync();
        var policy = new MembershipBookingPolicy(db, new Context());
        var target = new DateTime(2026, 10, 20, 16, 0, 0, DateTimeKind.Utc);

        var full = await policy.EvaluateAsync(fixture.Member.Id, target);

        Assert.Equal(MembershipBookingDecisionStatus.LimitReached, full.Status);
        Assert.Equal(8, full.Used);
        Assert.Equal(8, full.Allowed);

        db.Bookings.First().Status = BookingStatuses.Cancelled;
        await db.SaveChangesAsync();

        var makeupAvailable = await policy.EvaluateAsync(fixture.Member.Id, target);

        Assert.Equal(MembershipBookingDecisionStatus.Allowed, makeupAvailable.Status);
        Assert.Equal(7, makeupAvailable.Used);
        Assert.Equal(8, makeupAvailable.Allowed);
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

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static (Studio Studio, Member Member) AddFixedScheduleMembership(
        FitnessStudioDbContext db)
    {
        var now = DateTime.UtcNow;
        var studio = new Studio
        {
            Id = 1,
            Name = "Studio",
            Timezone = "Europe/Zagreb",
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        var member = new Member
        {
            Id = 1,
            StudioId = studio.Id,
            Studio = studio,
            FirstName = "Ana",
            LastName = "Horvat",
            Email = "ana@example.test",
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        var plan = new MembershipPlan
        {
            Id = 1,
            StudioId = studio.Id,
            Studio = studio,
            Name = "2x tjedno",
            BillingPeriodMonths = 1,
            SessionLimit = 2,
            SessionLimitPeriod = "week",
            PriceAmount = 70,
            Currency = "EUR",
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        db.AddRange(studio, member, plan, new MemberMembership
        {
            Id = 1,
            StudioId = studio.Id,
            Studio = studio,
            MemberId = member.Id,
            Member = member,
            MembershipPlanId = plan.Id,
            MembershipPlan = plan,
            StartsOn = new DateOnly(2026, 9, 1),
            BillingStartsOn = new DateOnly(2026, 10, 3),
            CreatedAt = now,
            UpdatedAt = now
        });

        AddFixedSchedule(db, studio, member, 1, 4);
        AddFixedSchedule(db, studio, member, 2, 5);
        return (studio, member);
    }

    private static void AddFixedSchedule(
        FitnessStudioDbContext db,
        Studio studio,
        Member member,
        long id,
        short dayOfWeek)
    {
        var now = DateTime.UtcNow;
        var recurring = new RecurringClassSchedule
        {
            Id = id,
            StudioId = studio.Id,
            Studio = studio,
            ClassTypeId = 1,
            TrainerId = 1,
            DayOfWeek = dayOfWeek,
            StartsAtTime = new TimeOnly(18, 0),
            DurationMinutes = 60,
            Capacity = 12,
            ValidFrom = new DateOnly(2026, 9, 1),
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        db.AddRange(recurring, new MemberFixedSchedule
        {
            Id = id,
            StudioId = studio.Id,
            Studio = studio,
            MemberId = member.Id,
            Member = member,
            RecurringScheduleId = recurring.Id,
            RecurringSchedule = recurring,
            StartsOn = new DateOnly(2026, 9, 1),
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        });
    }

    private static void AddBooking(
        FitnessStudioDbContext db,
        (Studio Studio, Member Member) fixture,
        long id,
        string status,
        DateTime startsAt)
    {
        var now = DateTime.UtcNow;
        var session = new ClassSession
        {
            Id = id,
            StudioId = fixture.Studio.Id,
            Studio = fixture.Studio,
            ClassTypeId = 1,
            TrainerId = 1,
            StartsAt = startsAt,
            EndsAt = startsAt.AddHours(1),
            Capacity = 12,
            Status = "scheduled",
            CreatedAt = now,
            UpdatedAt = now
        };
        db.AddRange(session, new Booking
        {
            Id = id,
            StudioId = fixture.Studio.Id,
            Studio = fixture.Studio,
            MemberId = fixture.Member.Id,
            Member = fixture.Member,
            ClassSessionId = session.Id,
            ClassSession = session,
            Status = status,
            BookingSource = "fixed_schedule",
            BookedAt = now,
            CreatedAt = now,
            UpdatedAt = now
        });
    }

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "ana@example.test";
        public long StudioId => 1;
        public long? MemberId => 1;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Member };
        public bool IsMemberOnly => true;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
