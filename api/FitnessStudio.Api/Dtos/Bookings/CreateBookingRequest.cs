using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Bookings;

public class CreateBookingRequest
{
    [Range(1, long.MaxValue)]
    public long MemberId { get; set; }

    [Range(1, long.MaxValue)]
    public long ClassSessionId { get; set; }
}
