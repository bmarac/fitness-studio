namespace FitnessStudio.Api.Domain.Bookings;

public static class BookingStatuses
{
    public const string Booked = "booked";
    public const string Cancelled = "cancelled";
    public const string Attended = "attended";
    public const string NoShow = "no_show";
    public const string Waitlisted = "waitlisted";

    public static readonly string[] All =
    [
        Booked,
        Cancelled,
        Attended,
        NoShow,
        Waitlisted
    ];

    public static readonly string[] Active =
    [
        Booked,
        Attended,
        NoShow,
        Waitlisted
    ];

    public static readonly string[] CapacityCounting =
    [
        Booked,
        Attended,
        NoShow
    ];

    public static bool IsValid(string status)
    {
        return All.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}
