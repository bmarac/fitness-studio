namespace FitnessStudio.Api.Domain.Bookings;

public static class BookingStatuses
{
    public const string Booked = "booked";
    public const string Cancelled = "cancelled";
    public const string LateCancelled = "late_cancelled";
    public const string Attended = "attended";
    public const string NoShow = "no_show";
    public const string Waitlisted = "waitlisted";

    public static readonly string[] All =
    [
        Booked,
        Cancelled,
        LateCancelled,
        Attended,
        NoShow,
        Waitlisted
    ];

    public static readonly string[] BlocksDuplicateBooking =
    [
        Booked,
        Attended,
        NoShow,
        Waitlisted,
        LateCancelled
    ];

    public static readonly string[] OccupiesCapacity =
    [
        Booked,
        Attended,
        NoShow
    ];

    public static readonly string[] CountsAgainstMembership =
    [
        Booked,
        Attended,
        NoShow,
        LateCancelled
    ];

    public static readonly string[] ManuallyAssignable =
    [
        Booked,
        Cancelled,
        Attended,
        NoShow,
        Waitlisted
    ];

    public static bool IsValid(string status)
    {
        return All.Contains(status, StringComparer.OrdinalIgnoreCase);
    }

    public static bool IsManuallyAssignable(string status)
    {
        return ManuallyAssignable.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}
