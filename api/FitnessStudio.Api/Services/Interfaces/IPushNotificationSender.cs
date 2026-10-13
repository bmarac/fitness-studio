namespace FitnessStudio.Api.Services.Interfaces;

public interface IPushNotificationSender
{
    bool IsEnabled { get; }
    Task<PushDeliveryResult> SendAsync(PushMessage message, string token, CancellationToken cancellationToken);
}

public record PushMessage(long NotificationId, string Type, string Title, string Body, long StudioId);

public enum PushDeliveryResult
{
    Delivered,
    Retry,
    InvalidToken
}
