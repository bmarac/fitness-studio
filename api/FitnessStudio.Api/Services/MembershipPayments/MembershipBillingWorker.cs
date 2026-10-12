using FitnessStudio.Api.Services.Interfaces;

namespace FitnessStudio.Api.Services.MembershipPayments;

public class MembershipBillingWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<MembershipBillingWorker> _logger;
    public MembershipBillingWorker(IServiceScopeFactory scopeFactory, ILogger<MembershipBillingWorker> logger) { _scopeFactory = scopeFactory; _logger = logger; }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                await scope.ServiceProvider.GetRequiredService<IMembershipBillingProcessor>().ProcessAsync(stoppingToken);
            }
            catch (Exception exception) when (!stoppingToken.IsCancellationRequested) { _logger.LogError(exception, "Membership billing processing failed."); }
            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
        }
    }
}
