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

public class MemberFixedScheduleMoveTests
{
    [Fact]
    public async Task MovePreservesPastAndTransfersFutureFixedBookings()
    {
        await using var db = CreateDatabase();
        var now = DateTime.UtcNow;
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(now, timezone));
        var member = Member(11, "Iva", "Ivic");
        var source = Schedule(41, 8, today, 12);
        var target = Schedule(42, 8, today, 12);
        var assignment = new MemberFixedSchedule
        {
            Id = 51,
            StudioId = 1,
            MemberId = member.Id,
            RecurringScheduleId = source.Id,
            StartsOn = today.AddDays(-30),
            Status = "active",
            CreatedAt = now.AddDays(-30),
            UpdatedAt = now.AddDays(-30)
        };
        var pastSourceSession = Session(61, source, now.AddDays(-7));
        var futureSourceSession = Session(62, source, now.AddDays(1));
        var targetSession = Session(63, target, now.AddDays(2));
        var pastBooking = Booking(71, member, pastSourceSession, BookingStatuses.Booked, now);
        var futureBooking = Booking(72, member, futureSourceSession, BookingStatuses.Booked, now);

        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(8),
            member,
            source,
            target,
            assignment,
            pastSourceSession,
            futureSourceSession,
            targetSession,
            pastBooking,
            futureBooking);
        await db.SaveChangesAsync();

        var service = new MemberFixedSchedulesService(
            db,
            new CurrentUserContext(AuthRoles.Admin),
            new AllowMembershipPolicy());

        var result = await service.MoveScheduleAsync(
            assignment.Id,
            new MoveMemberFixedScheduleRequest { TargetRecurringScheduleId = target.Id });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal("cancelled", assignment.Status);
        Assert.Equal(BookingStatuses.Booked, pastBooking.Status);
        Assert.Equal(BookingStatuses.Cancelled, futureBooking.Status);
        Assert.Equal("fixed_assignment", futureBooking.CancellationReason);

        var movedAssignment = await db.MemberFixedSchedules.SingleAsync(item =>
            item.RecurringScheduleId == target.Id && item.MemberId == member.Id);
        Assert.Equal("active", movedAssignment.Status);
        Assert.Equal(today, movedAssignment.StartsOn);

        var targetBooking = await db.Bookings.SingleAsync(item =>
            item.ClassSessionId == targetSession.Id && item.MemberId == member.Id);
        Assert.Equal(BookingStatuses.Booked, targetBooking.Status);
        Assert.Equal("fixed_schedule", targetBooking.BookingSource);
    }

    [Fact]
    public async Task MoveRejectsFullTargetWithoutChangingSource()
    {
        await using var db = CreateDatabase();
        var now = DateTime.UtcNow;
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(now, timezone));
        var sourceMember = Member(11, "Iva", "Ivic");
        var targetMember = Member(12, "Ana", "Anic");
        var source = Schedule(41, 8, today, 12);
        var target = Schedule(42, 8, today, 1);
        var sourceAssignment = Assignment(51, sourceMember, source, today);
        var targetAssignment = Assignment(52, targetMember, target, today);

        db.AddRange(
            Studio(timezone.Id),
            ClassType(),
            Trainer(8),
            sourceMember,
            targetMember,
            source,
            target,
            sourceAssignment,
            targetAssignment);
        await db.SaveChangesAsync();

        var service = new MemberFixedSchedulesService(
            db,
            new CurrentUserContext(AuthRoles.Admin),
            new AllowMembershipPolicy());

        var result = await service.MoveScheduleAsync(
            sourceAssignment.Id,
            new MoveMemberFixedScheduleRequest { TargetRecurringScheduleId = target.Id });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("active", sourceAssignment.Status);
        Assert.Single(await db.MemberFixedSchedules.Where(item => item.MemberId == sourceMember.Id).ToListAsync());
    }

    private static FitnessStudioDbContext CreateDatabase()
        => new(new DbContextOptionsBuilder<FitnessStudioDbContext>()
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

    private static Trainer Trainer(long id) => new()
    {
        Id = id,
        StudioId = 1,
        FirstName = "Trener",
        LastName = "Test",
        Email = $"trainer{id}@example.com",
        Status = "active"
    };

    private static Member Member(long id, string firstName, string lastName) => new()
    {
        Id = id,
        StudioId = 1,
        FirstName = firstName,
        LastName = lastName,
        Email = $"member{id}@example.com",
        Status = "active"
    };

    private static RecurringClassSchedule Schedule(
        long id,
        long trainerId,
        DateOnly today,
        int capacity) => new()
    {
        Id = id,
        StudioId = 1,
        ClassTypeId = 5,
        TrainerId = trainerId,
        DayOfWeek = 1,
        StartsAtTime = new TimeOnly(17, 0),
        DurationMinutes = 60,
        Capacity = capacity,
        ValidFrom = today.AddDays(-30),
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static MemberFixedSchedule Assignment(
        long id,
        Member member,
        RecurringClassSchedule schedule,
        DateOnly today) => new()
    {
        Id = id,
        StudioId = 1,
        MemberId = member.Id,
        RecurringScheduleId = schedule.Id,
        StartsOn = today.AddDays(-7),
        Status = "active",
        CreatedAt = DateTime.UtcNow.AddDays(-7),
        UpdatedAt = DateTime.UtcNow.AddDays(-7)
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
        string status,
        DateTime now) => new()
    {
        Id = id,
        StudioId = 1,
        MemberId = member.Id,
        ClassSessionId = session.Id,
        BookingSource = "fixed_schedule",
        Status = status,
        BookedAt = now.AddDays(-14),
        CreatedAt = now.AddDays(-14),
        UpdatedAt = now.AddDays(-14)
    };

    private sealed class CurrentUserContext(string role) : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { role };
        public bool IsMemberOnly => false;
        public bool IsInRole(string expectedRole) => Roles.Contains(expectedRole);
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
}
