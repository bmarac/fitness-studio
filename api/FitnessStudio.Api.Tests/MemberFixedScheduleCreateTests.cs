using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MemberFixedSchedules;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberFixedScheduleCreateTests
{
    [Fact]
    public async Task CreateAssignsMemberAndBackfillsEligibleFutureSessions()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var startsOn = today.AddDays(1);
        var member = Member(11);
        var otherMember = Member(12);
        var schedule = Schedule(41, startsOn.AddDays(-30), 1);
        var beforeStart = Session(61, schedule, UtcAt(today, timezone));
        var available = Session(62, schedule, UtcAt(startsOn, timezone));
        var full = Session(63, schedule, UtcAt(startsOn.AddDays(7), timezone));
        var occupied = Booking(71, otherMember, full, BookingStatuses.Booked);

        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(),
            member,
            otherMember,
            schedule,
            beforeStart,
            available,
            full,
            occupied);
        AddMembership(db, member, today.AddDays(-30));
        await db.SaveChangesAsync();

        var service = Service(db, new AllowMembershipPolicy());
        var result = await service.CreateScheduleAsync(Request(member.Id, schedule.Id, startsOn));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var assignment = await db.MemberFixedSchedules.SingleAsync();
        Assert.Equal(startsOn, assignment.StartsOn);
        Assert.Equal("active", assignment.Status);
        Assert.False(await db.Bookings.AnyAsync(item =>
            item.MemberId == member.Id && item.ClassSessionId == beforeStart.Id));

        var availableBooking = await db.Bookings.SingleAsync(item =>
            item.MemberId == member.Id && item.ClassSessionId == available.Id);
        Assert.Equal(BookingStatuses.Booked, availableBooking.Status);
        Assert.Equal("fixed_schedule", availableBooking.BookingSource);

        var waitlistedBooking = await db.Bookings.SingleAsync(item =>
            item.MemberId == member.Id && item.ClassSessionId == full.Id);
        Assert.Equal(BookingStatuses.Waitlisted, waitlistedBooking.Status);
        Assert.Equal("fixed_schedule", waitlistedBooking.BookingSource);
    }

    [Fact]
    public async Task CreateSkipsSessionsNotCoveredByMembership()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var schedule = Schedule(41, today.AddDays(-30), 12);
        var session = Session(61, schedule, UtcAt(today.AddDays(1), timezone));
        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, schedule, session);
        AddMembership(db, member, today.AddDays(-30));
        await db.SaveChangesAsync();

        var service = Service(db, new DenyMembershipPolicy());
        var result = await service.CreateScheduleAsync(Request(member.Id, schedule.Id, today));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Single(await db.MemberFixedSchedules.ToListAsync());
        Assert.Empty(await db.Bookings.ToListAsync());
    }

    [Fact]
    public async Task CreateDoesNotRestoreLateCancelledSession()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var schedule = Schedule(41, today.AddDays(-30), 12);
        var session = Session(61, schedule, UtcAt(today.AddDays(1), timezone));
        var lateCancelled = Booking(
            71,
            member,
            session,
            BookingStatuses.LateCancelled);
        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(),
            member,
            schedule,
            session,
            lateCancelled);
        AddMembership(db, member, today.AddDays(-30));
        await db.SaveChangesAsync();

        var service = Service(db, new AllowMembershipPolicy());
        var result = await service.CreateScheduleAsync(
            Request(member.Id, schedule.Id, today));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(
            BookingStatuses.LateCancelled,
            (await db.Bookings.SingleAsync()).Status);
    }

    [Theory]
    [InlineData("inactive-member")]
    [InlineData("inactive-schedule")]
    [InlineData("already-assigned")]
    [InlineData("full")]
    public async Task CreateRejectsUnavailableAssignment(string scenario)
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var existingMember = Member(12);
        var schedule = Schedule(41, today.AddDays(-30), scenario == "full" ? 1 : 12);
        if (scenario == "inactive-member") member.Status = "inactive";
        if (scenario == "inactive-schedule") schedule.Status = "paused";

        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, existingMember, schedule);
        if (scenario == "already-assigned")
        {
            db.Add(Assignment(51, member, schedule, today));
        }
        if (scenario == "full")
        {
            db.Add(Assignment(52, existingMember, schedule, today));
        }
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .CreateScheduleAsync(Request(member.Id, schedule.Id, today));

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal(
            scenario is "already-assigned" or "full" ? 1 : 0,
            await db.MemberFixedSchedules.CountAsync());
    }

    [Theory]
    [InlineData(1, 0, true)]
    [InlineData(2, 1, true)]
    [InlineData(2, 2, false)]
    [InlineData(3, 2, true)]
    [InlineData(3, 3, false)]
    public async Task CreateEnforcesWeeklyFixedScheduleLimit(
        int weeklyLimit,
        int existingAssignments,
        bool expectedSuccess)
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, target);
        AddMembership(db, member, today.AddDays(-30), weeklyLimit);
        for (var index = 0; index < existingAssignments; index++)
        {
            var existing = Schedule(50 + index, today.AddDays(-30), 12);
            db.Add(existing);
            db.Add(Assignment(70 + index, member, existing, today.AddDays(-7)));
        }
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .CreateScheduleAsync(Request(member.Id, target.Id, today));

        Assert.Equal(
            expectedSuccess ? ServiceResultStatus.Success : ServiceResultStatus.Conflict,
            result.Status);
        Assert.Equal(
            existingAssignments + (expectedSuccess ? 1 : 0),
            await db.MemberFixedSchedules.CountAsync());
    }

    [Theory]
    [InlineData(null, null, true)]
    [InlineData(8, "month", false)]
    [InlineData(20, "membership", false)]
    public async Task CreateSupportsUnlimitedAndRejectsNonWeeklyLimitedPackages(
        int? sessionLimit,
        string? period,
        bool expectedSuccess)
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, target);
        AddMembership(db, member, today.AddDays(-30), sessionLimit, period);
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .CreateScheduleAsync(Request(member.Id, target.Id, today));

        Assert.Equal(
            expectedSuccess ? ServiceResultStatus.Success : ServiceResultStatus.Conflict,
            result.Status);
    }

    [Theory]
    [InlineData("missing")]
    [InlineData("future")]
    [InlineData("expired")]
    public async Task CreateRejectsMembershipThatDoesNotCoverStartDate(string scenario)
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, target);
        if (scenario != "missing")
        {
            AddMembership(
                db,
                member,
                scenario == "future" ? today.AddDays(1) : today.AddDays(-30),
                endsOn: scenario == "expired" ? today : null);
        }
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .CreateScheduleAsync(Request(member.Id, target.Id, today));

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(await db.MemberFixedSchedules.ToListAsync());
    }

    [Fact]
    public async Task CreateDoesNotCountPausedCancelledOrNonOverlappingAssignments()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        db.AddRange(Studio(timezone.Id), ClassType(), Trainer(), member, target);
        AddMembership(db, member, today.AddDays(-30), 1);

        var paused = Schedule(42, today.AddDays(-30), 12);
        var cancelled = Schedule(43, today.AddDays(-30), 12);
        var ended = Schedule(44, today.AddDays(-30), 12);
        db.AddRange(paused, cancelled, ended);
        var pausedAssignment = Assignment(51, member, paused, today.AddDays(-7));
        pausedAssignment.Status = "paused";
        var cancelledAssignment = Assignment(52, member, cancelled, today.AddDays(-7));
        cancelledAssignment.Status = "cancelled";
        var endedAssignment = Assignment(53, member, ended, today.AddDays(-30));
        endedAssignment.EndsOn = today.AddDays(-1);
        db.AddRange(pausedAssignment, cancelledAssignment, endedAssignment);
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .CreateScheduleAsync(Request(member.Id, target.Id, today));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
    }

    [Theory]
    [InlineData("active", false)]
    [InlineData("paused", true)]
    public async Task ReactivatingPausedAssignmentRechecksActivePackageUsage(
        string otherStatus,
        bool expectedSuccess)
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        var other = Schedule(42, today.AddDays(-30), 12);
        var paused = Assignment(51, member, target, today.AddDays(-7));
        paused.Status = "paused";
        var otherAssignment = Assignment(52, member, other, today.AddDays(-7));
        otherAssignment.Status = otherStatus;
        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(),
            member,
            target,
            other,
            paused,
            otherAssignment);
        AddMembership(db, member, today.AddDays(-30), 1);
        await db.SaveChangesAsync();

        var result = await Service(db, new AllowMembershipPolicy())
            .UpdateScheduleAsync(paused.Id, new UpdateMemberFixedScheduleRequest
            {
                MemberId = member.Id,
                RecurringScheduleId = target.Id,
                StartsOn = paused.StartsOn,
                Status = "active"
            });

        Assert.Equal(
            expectedSuccess ? ServiceResultStatus.Success : ServiceResultStatus.Conflict,
            result.Status);
    }

    [Fact]
    public async Task CreateRechecksLastPackagePlaceAfterMemberLock()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        var member = Member(11);
        var target = Schedule(41, today.AddDays(-30), 12);
        var concurrentSchedule = Schedule(42, today.AddDays(-30), 12);
        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(),
            member,
            target,
            concurrentSchedule);
        AddMembership(db, member, today.AddDays(-30), 1);
        await db.SaveChangesAsync();
        var policy = new LockCallbackMembershipPolicy(async () =>
        {
            db.Add(Assignment(51, member, concurrentSchedule, today));
            await db.SaveChangesAsync();
        });

        var result = await Service(db, policy)
            .CreateScheduleAsync(Request(member.Id, target.Id, today));

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Single(await db.MemberFixedSchedules.ToListAsync());
        Assert.Equal(concurrentSchedule.Id, (await db.MemberFixedSchedules.SingleAsync()).RecurringScheduleId);
    }

    private static MemberFixedSchedulesService Service(
        FitnessStudioDbContext db,
        IMembershipBookingPolicy policy) => new(
            db,
            new CurrentUserContext(),
            policy);

    private static CreateMemberFixedScheduleRequest Request(
        long memberId,
        long scheduleId,
        DateOnly startsOn) => new()
        {
            MemberId = memberId,
            RecurringScheduleId = scheduleId,
            StartsOn = startsOn,
            Status = "active"
        };

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options);

    private static Studio Studio(string timezone) => new()
    {
        Id = 1,
        Name = "Studio",
        Timezone = timezone,
        Status = "active"
    };

    private static ClassType ClassType() => new()
    {
        Id = 5,
        StudioId = 1,
        Name = "Pilates",
        DifficultyLevel = "all",
        Status = "active"
    };

    private static Trainer Trainer() => new()
    {
        Id = 8,
        StudioId = 1,
        FirstName = "Filip",
        LastName = "Saric",
        Email = "filip@example.com",
        Status = "active"
    };

    private static Member Member(long id) => new()
    {
        Id = id,
        StudioId = 1,
        FirstName = $"Member{id}",
        LastName = "Test",
        Email = $"member{id}@example.com",
        Status = "active"
    };

    private static void AddMembership(
        FitnessStudioDbContext db,
        Member member,
        DateOnly startsOn,
        int? sessionLimit = 2,
        string? period = "week",
        DateOnly? endsOn = null)
    {
        var plan = new MembershipPlan
        {
            Id = member.Id,
            StudioId = 1,
            Name = $"Plan {member.Id}",
            BillingPeriodMonths = 1,
            SessionLimit = sessionLimit,
            SessionLimitPeriod = period,
            PriceAmount = 50,
            Currency = "EUR",
            Status = "active"
        };
        db.AddRange(plan, new MemberMembership
        {
            Id = member.Id,
            StudioId = 1,
            MemberId = member.Id,
            Member = member,
            MembershipPlanId = plan.Id,
            MembershipPlan = plan,
            StartsOn = startsOn,
            EndsOn = endsOn
        });
    }

    private static RecurringClassSchedule Schedule(
        long id,
        DateOnly validFrom,
        int capacity) => new()
        {
            Id = id,
            StudioId = 1,
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(17, 0),
            DurationMinutes = 60,
            Capacity = capacity,
            ValidFrom = validFrom,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static MemberFixedSchedule Assignment(
        long id,
        Member member,
        RecurringClassSchedule schedule,
        DateOnly startsOn) => new()
        {
            Id = id,
            StudioId = 1,
            MemberId = member.Id,
            RecurringScheduleId = schedule.Id,
            StartsOn = startsOn,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static ClassSession Session(
        long id,
        RecurringClassSchedule schedule,
        DateTime startsAt) => new()
        {
            Id = id,
            StudioId = 1,
            ClassTypeId = schedule.ClassTypeId,
            TrainerId = schedule.TrainerId,
            RecurringScheduleId = schedule.Id,
            StartsAt = startsAt,
            EndsAt = startsAt.AddHours(1),
            Capacity = schedule.Capacity,
            Status = ClassSessionStatuses.Scheduled,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static Booking Booking(
        long id,
        Member member,
        ClassSession session,
        string status) => new()
        {
            Id = id,
            StudioId = 1,
            MemberId = member.Id,
            ClassSessionId = session.Id,
            BookingSource = "admin",
            Status = status,
            BookedAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static DateTime UtcAt(DateOnly date, TimeZoneInfo timezone) =>
        TimeZoneInfo.ConvertTimeToUtc(date.ToDateTime(new TimeOnly(17, 0)), timezone);

    private sealed class CurrentUserContext : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class AllowMembershipPolicy : IMembershipBookingPolicy
    {
        public Task AcquireMemberLockAsync(long memberId) => Task.CompletedTask;

        public Task<MembershipBookingDecision> EvaluateAsync(
            long memberId,
            DateTime classSessionStartsAt,
            long? ignoredBookingId = null) => Task.FromResult(
                new MembershipBookingDecision(MembershipBookingDecisionStatus.Allowed));
    }

    private sealed class DenyMembershipPolicy : IMembershipBookingPolicy
    {
        public Task AcquireMemberLockAsync(long memberId) => Task.CompletedTask;

        public Task<MembershipBookingDecision> EvaluateAsync(
            long memberId,
            DateTime classSessionStartsAt,
            long? ignoredBookingId = null) => Task.FromResult(
                new MembershipBookingDecision(MembershipBookingDecisionStatus.MissingMembership));
    }

    private sealed class LockCallbackMembershipPolicy(Func<Task> callback)
        : IMembershipBookingPolicy
    {
        public async Task AcquireMemberLockAsync(long memberId) => await callback();

        public Task<MembershipBookingDecision> EvaluateAsync(
            long memberId,
            DateTime classSessionStartsAt,
            long? ignoredBookingId = null) => Task.FromResult(
                new MembershipBookingDecision(MembershipBookingDecisionStatus.Allowed));
    }
}
