using FitnessStudio.Api.Data;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Notifications;

public sealed class PushNotificationProcessor : IPushNotificationProcessor
{
    private readonly FitnessStudioDbContext _db;
    private readonly IPushNotificationSender _sender;
    private readonly ILogger<PushNotificationProcessor> _logger;

    public PushNotificationProcessor(
        FitnessStudioDbContext db,
        IPushNotificationSender sender,
        ILogger<PushNotificationProcessor> logger)
    {
        _db = db;
        _sender = sender;
        _logger = logger;
    }

    public async Task ProcessAsync(CancellationToken cancellationToken = default)
    {
        if (!_sender.IsEnabled) return;

        var pending = await _db.AppNotifications
            .Where(item => item.PushedAt == null)
            .OrderBy(item => item.CreatedAt)
            .Take(100)
            .ToListAsync(cancellationToken);

        foreach (var notification in pending)
        {
            var tokens = await _db.AppUserDeviceTokens
                .Where(item => item.AppUserId == notification.AppUserId)
                .ToListAsync(cancellationToken);
            var delivered = false;
            var message = new PushMessage(
                notification.Id,
                notification.NotificationType,
                notification.Title,
                notification.Body,
                notification.StudioId);

            foreach (var token in tokens)
            {
                var result = await _sender.SendAsync(message, token.Token, cancellationToken);
                if (result == PushDeliveryResult.Delivered)
                {
                    delivered = true;
                    _logger.LogInformation(
                        "Push notification {NotificationId} was delivered to a {Platform} device.",
                        notification.Id,
                        token.Platform);
                }
                else if (result == PushDeliveryResult.InvalidToken)
                {
                    _db.AppUserDeviceTokens.Remove(token);
                    _logger.LogInformation(
                        "Removed an invalid {Platform} push token for user {UserId}.",
                        token.Platform,
                        notification.AppUserId);
                }
                else
                {
                    _logger.LogWarning(
                        "Push notification {NotificationId} could not be delivered to a {Platform} device.",
                        notification.Id,
                        token.Platform);
                }
            }

            if (delivered) notification.PushedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(cancellationToken);
    }
}
