using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.Extensions.Options;

namespace FitnessStudio.Api.Services.Notifications;

public sealed class PushNotificationWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<PushNotificationWorker> _logger;
    private readonly TimeSpan _interval;

    public PushNotificationWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<PushNotificationWorker> logger,
        IOptions<FirebaseMessagingOptions> options)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
        _interval = TimeSpan.FromSeconds(Math.Max(5, options.Value.PollSeconds));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(_interval);
        do
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                await scope.ServiceProvider.GetRequiredService<IPushNotificationProcessor>()
                    .ProcessAsync(stoppingToken);
            }
            catch (Exception exception) when (!stoppingToken.IsCancellationRequested)
            {
                _logger.LogError(exception, "Push notification processing failed.");
            }
        }
        while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
