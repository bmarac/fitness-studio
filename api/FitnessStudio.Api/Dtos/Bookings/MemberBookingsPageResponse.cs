namespace FitnessStudio.Api.Dtos.Bookings;

public class MemberBookingsPageResponse
{
    public List<BookingResponse> Items { get; set; } = [];

    public int Page { get; set; }

    public int PageSize { get; set; }

    public bool HasNextPage { get; set; }
}
