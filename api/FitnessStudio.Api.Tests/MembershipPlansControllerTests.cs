using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipPlansControllerTests
{
    [Fact]
    public async Task GetPlansReturnsServiceItems()
    {
        var plans = new List<MembershipPlanResponse> { Plan() };
        var service = new FakeMembershipPlansService { GetPlansResult = plans };
        var controller = new MembershipPlansController(service);

        var action = await controller.GetPlans();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(plans, ok.Value);
    }

    [Fact]
    public async Task GetPlanReturnsItemAndForwardsId()
    {
        var plan = Plan();
        var service = new FakeMembershipPlansService
        {
            GetPlanResult = ServiceResult<MembershipPlanResponse>.Success(plan)
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.GetPlan(17);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(plan, ok.Value);
        Assert.Equal(17, service.LastGetPlanId);
    }

    [Fact]
    public async Task GetPlanMapsNotFound()
    {
        var service = new FakeMembershipPlansService
        {
            GetPlanResult = ServiceResult<MembershipPlanResponse>.NotFound(
                "Plan not found",
                "The membership plan does not exist.")
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.GetPlan(404);

        AssertProblem(action.Result, StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task CreatePlanReturnsCreatedAtGetPlanAndForwardsRequest()
    {
        var plan = Plan();
        var request = CreateRequest();
        var service = new FakeMembershipPlansService
        {
            CreatePlanResult = ServiceResult<MembershipPlanResponse>.Success(plan)
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.CreatePlan(request);

        var created = Assert.IsType<CreatedAtActionResult>(action.Result);
        Assert.Equal(nameof(MembershipPlansController.GetPlan), created.ActionName);
        Assert.Equal(plan.Id, created.RouteValues?["id"]);
        Assert.Same(plan, created.Value);
        Assert.Same(request, service.LastCreateRequest);
    }

    [Fact]
    public async Task CreatePlanMapsConflict()
    {
        var service = new FakeMembershipPlansService
        {
            CreatePlanResult = ServiceResult<MembershipPlanResponse>.Conflict(
                "Plan exists",
                "A plan with the same name already exists.")
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.CreatePlan(CreateRequest());

        AssertProblem(action.Result, StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task UpdatePlanReturnsNoContentAndForwardsArguments()
    {
        var request = UpdateRequest();
        var service = new FakeMembershipPlansService
        {
            UpdatePlanResult = ServiceResult.Success()
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.UpdatePlan(17, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(17, service.LastUpdatePlanId);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task UpdatePlanMapsNotFound()
    {
        var service = new FakeMembershipPlansService
        {
            UpdatePlanResult = ServiceResult.NotFound(
                "Plan not found",
                "The membership plan does not exist.")
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.UpdatePlan(404, UpdateRequest());

        AssertProblem(action, StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task DeletePlanReturnsNoContentAndForwardsId()
    {
        var service = new FakeMembershipPlansService
        {
            DeletePlanResult = ServiceResult.Success()
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.DeletePlan(17);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(17, service.LastDeletePlanId);
    }

    [Fact]
    public async Task DeletePlanMapsConflict()
    {
        var service = new FakeMembershipPlansService
        {
            DeletePlanResult = ServiceResult.Conflict(
                "Plan in use",
                "The membership plan is assigned to members.")
        };
        var controller = new MembershipPlansController(service);

        var action = await controller.DeletePlan(17);

        AssertProblem(action, StatusCodes.Status409Conflict);
    }

    [Fact]
    public void AuthorizationSeparatesReadsFromAdminMutations()
    {
        Assert.NotNull(typeof(MembershipPlansController).GetCustomAttribute<AuthorizeAttribute>());
        AssertNoMethodAuthorization(nameof(MembershipPlansController.GetPlans));
        AssertNoMethodAuthorization(nameof(MembershipPlansController.GetPlan));
        AssertAdminMethod(nameof(MembershipPlansController.CreatePlan));
        AssertAdminMethod(nameof(MembershipPlansController.UpdatePlan));
        AssertAdminMethod(nameof(MembershipPlansController.DeletePlan));
    }

    private static MembershipPlanResponse Plan()
        => new(17, "Monthly", null, 1, 8, "month", 40, "EUR", "active");

    private static CreateMembershipPlanRequest CreateRequest()
        => new()
        {
            Name = "Monthly",
            BillingPeriodMonths = 1,
            SessionLimit = 8,
            SessionLimitPeriod = "month",
            PriceAmount = 40,
            Currency = "EUR",
            Status = "active"
        };

    private static UpdateMembershipPlanRequest UpdateRequest()
        => new()
        {
            Name = "Monthly updated",
            BillingPeriodMonths = 1,
            SessionLimit = 10,
            SessionLimitPeriod = "month",
            PriceAmount = 45,
            Currency = "EUR",
            Status = "active"
        };

    private static void AssertNoMethodAuthorization(string methodName)
    {
        Assert.Null(typeof(MembershipPlansController)
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>());
    }

    private static void AssertAdminMethod(string methodName)
    {
        var attribute = typeof(MembershipPlansController)
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

    private sealed class FakeMembershipPlansService : IMembershipPlansService
    {
        public List<MembershipPlanResponse> GetPlansResult { get; init; } = [];
        public ServiceResult<MembershipPlanResponse> GetPlanResult { get; init; } = null!;
        public ServiceResult<MembershipPlanResponse> CreatePlanResult { get; init; } = null!;
        public ServiceResult UpdatePlanResult { get; init; } = null!;
        public ServiceResult DeletePlanResult { get; init; } = null!;
        public long? LastGetPlanId { get; private set; }
        public CreateMembershipPlanRequest? LastCreateRequest { get; private set; }
        public long? LastUpdatePlanId { get; private set; }
        public UpdateMembershipPlanRequest? LastUpdateRequest { get; private set; }
        public long? LastDeletePlanId { get; private set; }

        public Task<List<MembershipPlanResponse>> GetPlansAsync()
            => Task.FromResult(GetPlansResult);

        public Task<ServiceResult<MembershipPlanResponse>> GetPlanAsync(long id)
        {
            LastGetPlanId = id;
            return Task.FromResult(GetPlanResult);
        }

        public Task<ServiceResult<MembershipPlanResponse>> CreatePlanAsync(
            CreateMembershipPlanRequest request)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreatePlanResult);
        }

        public Task<ServiceResult> UpdatePlanAsync(
            long id,
            UpdateMembershipPlanRequest request)
        {
            LastUpdatePlanId = id;
            LastUpdateRequest = request;
            return Task.FromResult(UpdatePlanResult);
        }

        public Task<ServiceResult> DeletePlanAsync(long id)
        {
            LastDeletePlanId = id;
            return Task.FromResult(DeletePlanResult);
        }
    }
}
