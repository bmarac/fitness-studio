using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Services.Interfaces;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;

namespace FitnessStudio.Api.Services.Notifications;

public sealed class FirebasePushNotificationSender : IPushNotificationSender, IDisposable
{
    private readonly FirebaseMessagingOptions _options;
    private readonly ILogger<FirebasePushNotificationSender> _logger;
    private readonly Lazy<FirebaseApp> _app;

    public FirebasePushNotificationSender(
        IOptions<FirebaseMessagingOptions> options,
        ILogger<FirebasePushNotificationSender> logger)
    {
        _options = options.Value;
        _logger = logger;
        _app = new Lazy<FirebaseApp>(CreateApp);
    }

    public bool IsEnabled => _options.Enabled;

    public async Task<PushDeliveryResult> SendAsync(
        PushMessage message,
        string token,
        CancellationToken cancellationToken)
    {
        if (!IsEnabled) return PushDeliveryResult.Retry;

        try
        {
            await FirebaseMessaging.GetMessaging(_app.Value).SendAsync(new Message
            {
                Fid = token,
                Notification = new Notification { Title = message.Title, Body = message.Body },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = "membership_reminders",
                        Sound = "default"
                    }
                },
                Apns = new ApnsConfig
                {
                    Headers = new Dictionary<string, string> { ["apns-priority"] = "10" },
                    Aps = new Aps { Sound = "default" }
                },
                Data = new Dictionary<string, string>
                {
                    ["notification_id"] = message.NotificationId.ToString(),
                    ["notification_type"] = message.Type,
                    ["studio_id"] = message.StudioId.ToString()
                }
            }, cancellationToken);
            return PushDeliveryResult.Delivered;
        }
        catch (FirebaseMessagingException exception)
            when (exception.MessagingErrorCode == MessagingErrorCode.Unregistered)
        {
            return PushDeliveryResult.InvalidToken;
        }
        catch (Exception exception) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(exception, "FCM delivery failed for notification {NotificationId}.", message.NotificationId);
            return PushDeliveryResult.Retry;
        }
    }

    private FirebaseApp CreateApp()
    {
        GoogleCredential credential = _options.UseApplicationDefaultCredentials
            ? GoogleCredential.GetApplicationDefault()
            : CredentialFactory.FromFile<ServiceAccountCredential>(_options.CredentialPath!)
                .ToGoogleCredential();
        return FirebaseApp.Create(new AppOptions
        {
            Credential = credential,
            ProjectId = _options.ProjectId
        }, $"fitness-studio-{Guid.NewGuid():N}");
    }

    public void Dispose()
    {
        if (_app.IsValueCreated) _app.Value.Delete();
    }
}
