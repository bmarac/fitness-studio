using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.RecurringClassSchedules;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class RecurringScheduleLifecycleTests
{
    [Fact]
    public void CreationAllowsAdminAndAssignedTrainerButRejectsOtherUsers()
    {
        Assert.Null(RecurringClassSchedulesService.AuthorizeScheduleCreation(
            new UserContext(AuthRoles.Admin),
            8));
        Assert.Null(RecurringClassSchedulesService.AuthorizeScheduleCreation(
            new UserContext(AuthRoles.Trainer, trainerId: 8),
            8));

        var otherTrainer = RecurringClassSchedulesService.AuthorizeScheduleCreation(
            new UserContext(AuthRoles.Trainer, trainerId: 7),
            8);
        var member = RecurringClassSchedulesService.AuthorizeScheduleCreation(
            new UserContext(AuthRoles.Member),
            8);

        Assert.Equal(ServiceResultStatus.Forbidden, otherTrainer?.Status);
        Assert.Equal(ServiceResultStatus.Forbidden, member?.Status);
    }

    [Fact]
    public void PauseMarksOnlyActiveBookingsAndIdentifiesRestorableFixedBooking()
    {
        var now = new DateTime(2026, 10, 9, 10, 0, 0, DateTimeKind.Utc);
        var session = new ClassSession
        {
            StartsAt = new DateTime(2026, 10, 12, 16, 0, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 10, 12, 17, 0, 0, DateTimeKind.Utc),
            Capacity = 10,
            Status = ClassSessionStatuses.Scheduled
        };
        session.Bookings.Add(Booking(1, "fixed_schedule", BookingStatuses.Booked));
        session.Bookings.Add(Booking(2, "self_service", BookingStatuses.Booked));
        session.Bookings.Add(Booking(4, "fixed_schedule", BookingStatuses.LateCancelled));
        session.Bookings.Add(Booking(
            3,
            "fixed_schedule",
            BookingStatuses.Cancelled,
            "single_session"));

        var schedule = new RecurringClassSchedule
        {
            StudioId = 1,
            ClassSessions = [session],
            MemberFixedSchedules =
            [
                Assignment(1),
                Assignment(2),
                Assignment(3)
            ]
        };

        RecurringClassSchedulesService.CancelScheduledSessions(
            schedule,
            new DateTime(2026, 10, 12, 0, 0, 0, DateTimeKind.Utc),
            now,
            "schedule_paused");

        Assert.Equal(ClassSessionStatuses.Cancelled, session.Status);
        Assert.Equal("schedule_paused", session.CancellationReason);
        Assert.Equal("schedule_paused", session.Bookings.Single(item => item.MemberId == 1).CancellationReason);
        Assert.Equal("schedule_paused", session.Bookings.Single(item => item.MemberId == 2).CancellationReason);
        Assert.Equal("single_session", session.Bookings.Single(item => item.MemberId == 3).CancellationReason);
        Assert.Equal(
            "schedule_paused_late_cancelled",
            session.Bookings.Single(item => item.MemberId == 4).CancellationReason);

        Assert.True(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 1)));
        Assert.False(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 2)));
        Assert.False(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 3)));
        Assert.False(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 4)));

        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 1).Status);
        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 2).Status);
        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 3).Status);
        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 4).Status);
    }

    private static Booking Booking(
        long memberId,
        string source,
        string status,
        string? cancellationReason = null)
    {
        return new Booking
        {
            MemberId = memberId,
            BookingSource = source,
            Status = status,
            CancellationReason = cancellationReason
        };
    }

    private static MemberFixedSchedule Assignment(long memberId)
    {
        return new MemberFixedSchedule
        {
            MemberId = memberId,
            Status = "active",
            StartsOn = new DateOnly(2026, 1, 1),
            CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        };
    }

    private sealed class UserContext(string role, long? trainerId = null) : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => trainerId;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { role };
        public bool IsMemberOnly => role == AuthRoles.Member;
        public bool IsInRole(string expectedRole) => Roles.Contains(expectedRole);
    }
}
