using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class StudioSettingsControllerTests
{
    [Fact]
    public async Task GetSettingsReturnsServiceItems()
    {
        var items = new List<StudioSettingResponse> { Setting() };
        var service = new FakeStudioSettingsService { GetSettingsResult = items };
        var controller = new StudioSettingsController(service);

        var action = await controller.GetSettings();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(items, ok.Value);
    }

    [Fact]
    public async Task GetSettingReturnsItemAndForwardsKey()
    {
        var item = Setting();
        var service = new FakeStudioSettingsService
        {
            GetSettingResult = ServiceResult<StudioSettingResponse>.Success(item)
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.GetSetting("timezone");

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(item, ok.Value);
        Assert.Equal("timezone", service.LastGetSetting);
    }

    [Fact]
    public async Task GetSettingMapsNotFound()
    {
        var service = new FakeStudioSettingsService
        {
            GetSettingResult = ServiceResult<StudioSettingResponse>.NotFound(
                "Setting not found",
                "The setting does not exist.")
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.GetSetting("missing");

        AssertProblem(action.Result, StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task UpsertSettingReturnsItemAndForwardsArguments()
    {
        var item = Setting();
        var request = new UpsertStudioSettingRequest
        {
            Value = "Europe/Zagreb",
            ValueType = "string"
        };
        var service = new FakeStudioSettingsService
        {
            UpsertResult = ServiceResult<StudioSettingResponse>.Success(item)
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.UpsertSetting("timezone", request);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(item, ok.Value);
        Assert.Equal("timezone", service.LastUpsertSetting);
        Assert.Same(request, service.LastUpsertRequest);
    }

    [Fact]
    public async Task UpsertSettingMapsConflict()
    {
        var service = new FakeStudioSettingsService
        {
            UpsertResult = ServiceResult<StudioSettingResponse>.Conflict(
                "Invalid setting",
                "The value is not valid.")
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.UpsertSetting(
            "timezone",
            new UpsertStudioSettingRequest());

        AssertProblem(action.Result, StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task DeleteSettingReturnsNoContentAndForwardsKey()
    {
        var service = new FakeStudioSettingsService
        {
            DeleteResult = ServiceResult.Success()
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.DeleteSetting("timezone");

        Assert.IsType<NoContentResult>(action);
        Assert.Equal("timezone", service.LastDeleteSetting);
    }

    [Fact]
    public async Task DeleteSettingMapsNotFound()
    {
        var service = new FakeStudioSettingsService
        {
            DeleteResult = ServiceResult.NotFound(
                "Setting not found",
                "The setting does not exist.")
        };
        var controller = new StudioSettingsController(service);

        var action = await controller.DeleteSetting("missing");

        AssertProblem(action, StatusCodes.Status404NotFound);
    }

    [Fact]
    public void AuthorizationSeparatesReadsFromAdminMutations()
    {
        Assert.NotNull(typeof(StudioSettingsController).GetCustomAttribute<AuthorizeAttribute>());
        AssertNoMethodAuthorization(nameof(StudioSettingsController.GetSettings));
        AssertNoMethodAuthorization(nameof(StudioSettingsController.GetSetting));
        AssertAdminMethod(nameof(StudioSettingsController.UpsertSetting));
        AssertAdminMethod(nameof(StudioSettingsController.DeleteSetting));
    }

    private static StudioSettingResponse Setting()
        => new(1, "timezone", "Europe/Zagreb", "string");

    private static void AssertNoMethodAuthorization(string methodName)
    {
        Assert.Null(typeof(StudioSettingsController)
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>());
    }

    private static void AssertAdminMethod(string methodName)
    {
        var attribute = typeof(StudioSettingsController)
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>();
        Assert.Equal(AuthRoles.Admin, attribute?.Roles);
    }

    private static void AssertProblem(IActionResult? action, int statusCode)
    {
        var objectResult = Assert.IsType<ObjectResult>(action);
        Assert.Equal(statusCode, objectResult.StatusCode);
        Assert.Equal(statusCode, Assert.IsType<ProblemDetails>(objectResult.Value).Status);
    }

    private sealed class FakeStudioSettingsService : IStudioSettingsService
    {
        public List<StudioSettingResponse> GetSettingsResult { get; init; } = [];
        public ServiceResult<StudioSettingResponse> GetSettingResult { get; init; } = null!;
        public ServiceResult<StudioSettingResponse> UpsertResult { get; init; } = null!;
        public ServiceResult DeleteResult { get; init; } = null!;
        public string? LastGetSetting { get; private set; }
        public string? LastUpsertSetting { get; private set; }
        public UpsertStudioSettingRequest? LastUpsertRequest { get; private set; }
        public string? LastDeleteSetting { get; private set; }

        public Task<List<StudioSettingResponse>> GetSettingsAsync()
            => Task.FromResult(GetSettingsResult);

        public Task<ServiceResult<StudioSettingResponse>> GetSettingAsync(string setting)
        {
            LastGetSetting = setting;
            return Task.FromResult(GetSettingResult);
        }

        public Task<ServiceResult<StudioSettingResponse>> UpsertSettingAsync(
            string setting,
            UpsertStudioSettingRequest request)
        {
            LastUpsertSetting = setting;
            LastUpsertRequest = request;
            return Task.FromResult(UpsertResult);
        }

        public Task<ServiceResult> DeleteSettingAsync(string setting)
        {
            LastDeleteSetting = setting;
            return Task.FromResult(DeleteResult);
        }
    }
}
