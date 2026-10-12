using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Notifications;

public record AppNotificationResponse(long Id, long? PaymentObligationId, string Type, string Title, string Body, DateTime? ReadAt, DateTime CreatedAt);
public class RegisterDeviceTokenRequest
{
    [Required] public string Token { get; set; } = null!;
    [Required, RegularExpression("^(android|ios)$")] public string Platform { get; set; } = null!;
}
