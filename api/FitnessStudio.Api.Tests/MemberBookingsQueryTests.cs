using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Bookings;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberBookingsQueryTests
{
    private static readonly DateTime Now = new(2026, 10, 13, 12, 0, 0, DateTimeKind.Utc);

    [Fact]
    public void QueryValidationRejectsUnsupportedFiltersAndPageSizes()
    {
        var query = new MemberBookingsQuery
        {
            Filter = "upcoming",
            Page = 0,
            PageSize = 101
        };
        var validationResults = new List<ValidationResult>();

        var isValid = Validator.TryValidateObject(
            query,
            new ValidationContext(query),
            validationResults,
            validateAllProperties: true);

        Assert.False(isValid);
        Assert.Equal(3, validationResults.Count);
    }

    [Fact]
    public void ActiveReturnsOnlyFutureActiveBookingsInAscendingOrder()
    {
        var bookings = new[]
        {
            Booking(1, BookingStatuses.Booked, Now.AddHours(4), Now.AddHours(5)),
            Booking(2, BookingStatuses.Waitlisted, Now.AddHours(1), Now.AddHours(2)),
            Booking(3, BookingStatuses.Attended, Now.AddHours(2), Now.AddHours(3)),
            Booking(4, BookingStatuses.Booked, Now.AddHours(-2), Now.AddHours(-1)),
            Booking(5, BookingStatuses.Cancelled, Now.AddHours(3), Now.AddHours(4))
        }.AsQueryable();

        var result = BookingsService.FilterAndOrderMemberBookings(
            bookings,
            "active",
            Now).Select(booking => booking.Id).ToList();

        Assert.Equal([2, 1], result);
    }

    [Fact]
    public void CompletedIncludesMarkedAndElapsedBookingsInDescendingOrder()
    {
        var bookings = new[]
        {
            Booking(1, BookingStatuses.Attended, Now.AddDays(-2), Now.AddDays(-2).AddHours(1)),
            Booking(2, BookingStatuses.NoShow, Now.AddDays(-1), Now.AddDays(-1).AddHours(1)),
            Booking(3, BookingStatuses.Booked, Now.AddHours(-2), Now.AddHours(-1)),
            Booking(4, BookingStatuses.Booked, Now.AddHours(1), Now.AddHours(2)),
            Booking(5, BookingStatuses.Cancelled, Now.AddMinutes(-30), Now.AddMinutes(30)),
            Booking(6, BookingStatuses.LateCancelled, Now.AddDays(-3), Now.AddDays(-3).AddHours(1))
        }.AsQueryable();

        var result = BookingsService.FilterAndOrderMemberBookings(
            bookings,
            "completed",
            Now).Select(booking => booking.Id).ToList();

        Assert.Equal([3, 2, 1], result);
    }

    [Fact]
    public void CancelledAndAllUseNewestFirstWithStableIdTieBreaker()
    {
        var sameStart = Now.AddDays(-1);
        var bookings = new[]
        {
            Booking(1, BookingStatuses.Cancelled, sameStart, sameStart.AddHours(1)),
            Booking(2, BookingStatuses.Cancelled, sameStart, sameStart.AddHours(1)),
            Booking(3, BookingStatuses.Booked, Now.AddDays(1), Now.AddDays(1).AddHours(1)),
            Booking(4, BookingStatuses.LateCancelled, Now.AddDays(-2), Now.AddDays(-2).AddHours(1))
        }.AsQueryable();

        var cancelled = BookingsService.FilterAndOrderMemberBookings(
            bookings,
            "cancelled",
            Now).Select(booking => booking.Id).ToList();
        var all = BookingsService.FilterAndOrderMemberBookings(
            bookings,
            "all",
            Now).Select(booking => booking.Id).ToList();

        Assert.Equal([2, 1, 4], cancelled);
        Assert.Equal([3, 2, 1, 4], all);
    }

    private static Booking Booking(
        long id,
        string status,
        DateTime startsAt,
        DateTime endsAt)
    {
        return new Booking
        {
            Id = id,
            Status = status,
            ClassSession = new ClassSession
            {
                StartsAt = startsAt,
                EndsAt = endsAt
            }
        };
    }
}
