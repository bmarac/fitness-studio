using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class StudioConfigurationControllerTests
{
    [Fact]
    public async Task GetReturnsTheUnifiedConfiguration()
    {
        var expected = Configuration();
        var controller = new StudioConfigurationController(
            new FakeService { GetResult = expected });

        var action = await controller.Get();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(expected, ok.Value);
    }

    [Fact]
    public async Task UpdateForwardsTheCompleteRequest()
    {
        var expected = Configuration();
        var service = new FakeService
        {
            UpdateResult = ServiceResult<StudioConfigurationResponse>.Success(expected)
        };
        var controller = new StudioConfigurationController(service);
        var request = new UpdateStudioConfigurationRequest
        {
            JoinByCodeEnabled = true,
            JoinCode = "STAYFIT",
            RecipientName = "Stay Fit",
            Iban = "HR1210010051863000160",
            PaymentReference = "123",
            PaymentDescription = "Članarina"
        };

        var action = await controller.Update(request);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(expected, ok.Value);
        Assert.Same(request, service.LastUpdateRequest);
    }

    private static StudioConfigurationResponse Configuration() => new(
        true,
        "STAYFIT",
        "Stay Fit",
        "HR1210010051863000160",
        "HR00",
        "123",
        "Članarina",
        [1, 3],
        [5],
        new TimeOnly(9, 0),
        12,
        true);

    private sealed class FakeService : IStudioConfigurationService
    {
        public StudioConfigurationResponse GetResult { get; init; } = null!;
        public ServiceResult<StudioConfigurationResponse> UpdateResult { get; init; } = null!;
        public UpdateStudioConfigurationRequest? LastUpdateRequest { get; private set; }

        public Task<StudioConfigurationResponse> GetAsync() => Task.FromResult(GetResult);

        public Task<ServiceResult<StudioConfigurationResponse>> UpdateAsync(
            UpdateStudioConfigurationRequest request)
        {
            LastUpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }
    }
}
