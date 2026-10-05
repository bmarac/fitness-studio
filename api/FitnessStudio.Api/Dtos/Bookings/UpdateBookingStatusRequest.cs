using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;

namespace FitnessStudio.Api.Dtos.Bookings;

public class UpdateBookingStatusRequest
{
    [Required]
    [StringLength(30)]
    [AllowedBookingStatus]
    public string Status { get; set; } = null!;
}
