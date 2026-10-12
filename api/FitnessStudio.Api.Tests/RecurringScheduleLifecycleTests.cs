using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.RecurringClassSchedules;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class RecurringScheduleLifecycleTests
{
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

        Assert.True(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 1)));
        Assert.False(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 2)));
        Assert.False(RecurringClassSchedulesService.CanRestoreFixedBooking(
            session.Bookings.Single(item => item.MemberId == 3)));

        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 1).Status);
        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 2).Status);
        Assert.Equal(BookingStatuses.Cancelled, session.Bookings.Single(item => item.MemberId == 3).Status);
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
}
