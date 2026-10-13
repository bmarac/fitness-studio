using System.Threading.RateLimiting;
using FitnessStudio.Api.Data;
using Microsoft.AspNetCore.RateLimiting;

namespace FitnessStudio.Api.Services.Startup;

public static class ApiInfrastructureExtensions
{
    public static IServiceCollection AddApiInfrastructure(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            options.AddFixedWindowLimiter("auth", limiter =>
            {
                limiter.PermitLimit = 10;
                limiter.Window = TimeSpan.FromMinutes(1);
                limiter.QueueLimit = 0;
                limiter.AutoReplenishment = true;
            });
        });
        return services;
    }

    public static async Task<bool> UseApiInfrastructureAsync(
        this WebApplication app,
        string[] args)
    {
        if (args.FirstOrDefault() == "provision-studio")
        {
            await StudioProvisioningCommand.RunAsync(app.Services, args);
            return true;
        }
        app.UseRateLimiter();
        return false;
    }
}
