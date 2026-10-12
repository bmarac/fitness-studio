namespace FitnessStudio.Api.Services.Interfaces;

public interface IMembershipBillingProcessor
{
    Task ProcessAsync(CancellationToken cancellationToken = default);
}
