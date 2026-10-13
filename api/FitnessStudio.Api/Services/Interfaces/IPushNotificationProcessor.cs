namespace FitnessStudio.Api.Services.Interfaces;

public interface IPushNotificationProcessor
{
    Task ProcessAsync(CancellationToken cancellationToken = default);
}
