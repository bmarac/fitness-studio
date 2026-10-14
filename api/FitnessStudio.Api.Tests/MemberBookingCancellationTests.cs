using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Bookings;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberBookingCancellationTests
{
    private static readonly DateTime Now = new(2026, 10, 10, 12, 0, 0, DateTimeKind.Utc);

    [Theory]
    [InlineData(BookingStatuses.Booked)]
    [InlineData(BookingStatuses.Waitlisted)]
    public void FutureActiveBooking_CanBeCancelledByMember(string status)
    {
        var booking = Booking(status, ClassSessionStatuses.Scheduled, Now.AddHours(1));

        Assert.True(BookingsService.CanMemberCancel(booking, Now));
    }

    [Theory]
    [InlineData(BookingStatuses.Attended)]
    [InlineData(BookingStatuses.NoShow)]
    [InlineData(BookingStatuses.Cancelled)]
    public void InactiveBooking_CannotBeCancelledByMember(string status)
    {
        var booking = Booking(status, ClassSessionStatuses.Scheduled, Now.AddHours(1));

        Assert.False(BookingsService.CanMemberCancel(booking, Now));
    }

    [Fact]
    public void PastBooking_CannotBeCancelledByMember()
    {
        var booking = Booking(BookingStatuses.Booked, ClassSessionStatuses.Scheduled, Now.AddMinutes(-1));

        Assert.False(BookingsService.CanMemberCancel(booking, Now));
    }

    [Fact]
    public void CancelledClassSession_CannotBeCancelledByMember()
    {
        var booking = Booking(BookingStatuses.Booked, ClassSessionStatuses.Cancelled, Now.AddHours(1));

        Assert.False(BookingsService.CanMemberCancel(booking, Now));
    }

    [Fact]
    public void CancellationAtCutoffReturnsQuota()
    {
        var booking = Booking(
            BookingStatuses.Booked,
            ClassSessionStatuses.Scheduled,
            Now.AddHours(12));

        var status = BookingsService.GetCancellationStatus(booking, Now, 12);

        Assert.Equal(BookingStatuses.Cancelled, status);
    }

    [Fact]
    public void CancellationAfterCutoffIsLate()
    {
        var booking = Booking(
            BookingStatuses.Booked,
            ClassSessionStatuses.Scheduled,
            Now.AddHours(11).AddMinutes(59));

        var status = BookingsService.GetCancellationStatus(booking, Now, 12);

        Assert.Equal(BookingStatuses.LateCancelled, status);
    }

    [Fact]
    public void WaitlistedCancellationAlwaysReturnsRegularCancelledStatus()
    {
        var booking = Booking(
            BookingStatuses.Waitlisted,
            ClassSessionStatuses.Scheduled,
            Now.AddMinutes(1));

        var status = BookingsService.GetCancellationStatus(booking, Now, 12);

        Assert.Equal(BookingStatuses.Cancelled, status);
    }

    private static Booking Booking(string status, string classSessionStatus, DateTime startsAt)
    {
        return new Booking
        {
            Status = status,
            ClassSession = new ClassSession
            {
                Status = classSessionStatus,
                StartsAt = startsAt
            }
        };
    }
}
