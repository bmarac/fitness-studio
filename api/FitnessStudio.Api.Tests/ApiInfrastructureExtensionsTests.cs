using FitnessStudio.Api.Services.Startup;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ApiInfrastructureExtensionsTests
{
    [Fact]
    public async Task RegistersRateLimiterAndKeepsNormalStartupRunning()
    {
        var builder = WebApplication.CreateBuilder();
        builder.Services.AddApiInfrastructure();
        await using var app = builder.Build();

        var options = app.Services.GetRequiredService<IOptions<RateLimiterOptions>>().Value;
        var handledCommand = await app.UseApiInfrastructureAsync([]);

        Assert.False(handledCommand);
        Assert.NotNull(options);
    }
}
