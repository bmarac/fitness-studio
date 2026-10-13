using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MeasurementParameters;
using FitnessStudio.Api.Dtos.MemberMeasurements;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MeasurementControllersTests
{
    [Fact]
    public async Task ParameterControllerMapsSuccessAndForwardsArguments()
    {
        var response = Parameter();
        var service = new ParameterService
        {
            List = [response],
            Get = ServiceResult<MeasurementParameterResponse>.Success(response),
            Create = ServiceResult<MeasurementParameterResponse>.Success(response),
            Update = ServiceResult.Success(),
            Delete = ServiceResult.Success()
        };
        var controller = new MeasurementParametersController(service);
        var create = new CreateMeasurementParameterRequest();
        var update = new UpdateMeasurementParameterRequest();

        Assert.Same(service.List, Assert.IsType<OkObjectResult>((await controller.GetParameters()).Result).Value);
        Assert.Same(response, Assert.IsType<OkObjectResult>((await controller.GetParameter(7)).Result).Value);
        var created = Assert.IsType<CreatedAtActionResult>((await controller.CreateParameter(create)).Result);
        Assert.Equal(nameof(MeasurementParametersController.GetParameter), created.ActionName);
        Assert.Equal(11L, created.RouteValues!["id"]);
        Assert.Same(response, created.Value);
        Assert.IsType<NoContentResult>(await controller.UpdateParameter(8, update));
        Assert.IsType<NoContentResult>(await controller.DeleteParameter(9));
        Assert.Equal([7, 8, 9], service.Ids);
        Assert.Same(create, service.CreateRequest);
        Assert.Same(update, service.UpdateRequest);
    }

    [Fact]
    public async Task ParameterControllerMapsFailures()
    {
        var service = new ParameterService
        {
            Get = ServiceResult<MeasurementParameterResponse>.NotFound("missing", "detail"),
            Create = ServiceResult<MeasurementParameterResponse>.Conflict("duplicate", "detail"),
            Update = ServiceResult.Forbidden("forbidden", "detail"),
            Delete = ServiceResult.NotFound("missing", "detail")
        };
        var controller = new MeasurementParametersController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetParameter(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.CreateParameter(new CreateMeasurementParameterRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateParameter(1, new UpdateMeasurementParameterRequest()), 403);
        SchedulingControllerTestAssertions.Problem(await controller.DeleteParameter(1), 404);
    }

    [Fact]
    public async Task MemberControllerMapsSuccessAndForwardsArguments()
    {
        var measurement = Measurement();
        var latest = new MemberLatestMeasurementsResponse(5, []);
        var service = new MemberService
        {
            History = ServiceResult<List<MemberMeasurementResponse>>.Success([measurement]),
            Latest = ServiceResult<MemberLatestMeasurementsResponse>.Success(latest),
            Create = ServiceResult<MemberMeasurementResponse>.Success(measurement)
        };
        var controller = new MemberMeasurementsController(service);
        var request = new CreateMemberMeasurementRequest();

        Assert.NotNull(Assert.IsType<OkObjectResult>((await controller.GetMeasurements(5)).Result).Value);
        Assert.Same(latest, Assert.IsType<OkObjectResult>(
            (await controller.GetLatestMeasurements(6)).Result).Value);
        var created = Assert.IsType<CreatedAtActionResult>(
            (await controller.CreateMeasurement(7, request)).Result);
        Assert.Equal(nameof(MemberMeasurementsController.GetMeasurements), created.ActionName);
        Assert.Equal(7L, created.RouteValues!["memberId"]);
        Assert.Same(measurement, created.Value);
        Assert.Equal([5, 6, 7], service.MemberIds);
        Assert.Same(request, service.Request);
    }

    [Fact]
    public async Task MemberControllerMapsFailures()
    {
        var service = new MemberService
        {
            History = ServiceResult<List<MemberMeasurementResponse>>.Forbidden("no", "detail"),
            Latest = ServiceResult<MemberLatestMeasurementsResponse>.NotFound("missing", "detail"),
            Create = ServiceResult<MemberMeasurementResponse>.Conflict("invalid", "detail")
        };
        var controller = new MemberMeasurementsController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetMeasurements(1)).Result, 403);
        SchedulingControllerTestAssertions.Problem((await controller.GetLatestMeasurements(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.CreateMeasurement(1, new CreateMemberMeasurementRequest())).Result, 409);
    }

    [Fact]
    public void AuthorizationContractIsExplicit()
    {
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(typeof(MeasurementParametersController));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MeasurementParametersController), nameof(MeasurementParametersController.CreateParameter), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MeasurementParametersController), nameof(MeasurementParametersController.UpdateParameter), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MeasurementParametersController), nameof(MeasurementParametersController.DeleteParameter), AuthRoles.Admin);
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(typeof(MemberMeasurementsController));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(MemberMeasurementsController), nameof(MemberMeasurementsController.CreateMeasurement), AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            typeof(MemberMeasurementsController), nameof(MemberMeasurementsController.GetMeasurements));
    }

    private static MeasurementParameterResponse Parameter() =>
        new(11, "weight", "Weight", "kg", "decimal", "manual", null, 20, 500, 1, 1, "active");

    private static MemberMeasurementResponse Measurement() =>
        new(12, 7, DateTime.UtcNow, 1, null, []);

    private sealed class ParameterService : IMeasurementParametersService
    {
        public List<MeasurementParameterResponse> List { get; init; } = [];
        public ServiceResult<MeasurementParameterResponse> Get { get; init; } = null!;
        public ServiceResult<MeasurementParameterResponse> Create { get; init; } = null!;
        public ServiceResult Update { get; init; } = null!;
        public ServiceResult Delete { get; init; } = null!;
        public List<long> Ids { get; } = [];
        public CreateMeasurementParameterRequest? CreateRequest { get; private set; }
        public UpdateMeasurementParameterRequest? UpdateRequest { get; private set; }
        public Task<List<MeasurementParameterResponse>> GetParametersAsync() => Task.FromResult(List);
        public Task<ServiceResult<MeasurementParameterResponse>> GetParameterAsync(long id)
        { Ids.Add(id); return Task.FromResult(Get); }
        public Task<ServiceResult<MeasurementParameterResponse>> CreateParameterAsync(CreateMeasurementParameterRequest request)
        { CreateRequest = request; return Task.FromResult(Create); }
        public Task<ServiceResult> UpdateParameterAsync(long id, UpdateMeasurementParameterRequest request)
        { Ids.Add(id); UpdateRequest = request; return Task.FromResult(Update); }
        public Task<ServiceResult> DeleteParameterAsync(long id)
        { Ids.Add(id); return Task.FromResult(Delete); }
    }

    private sealed class MemberService : IMemberMeasurementsService
    {
        public ServiceResult<List<MemberMeasurementResponse>> History { get; init; } = null!;
        public ServiceResult<MemberLatestMeasurementsResponse> Latest { get; init; } = null!;
        public ServiceResult<MemberMeasurementResponse> Create { get; init; } = null!;
        public List<long> MemberIds { get; } = [];
        public CreateMemberMeasurementRequest? Request { get; private set; }
        public Task<ServiceResult<List<MemberMeasurementResponse>>> GetMeasurementsAsync(long memberId)
        { MemberIds.Add(memberId); return Task.FromResult(History); }
        public Task<ServiceResult<MemberLatestMeasurementsResponse>> GetLatestMeasurementsAsync(long memberId)
        { MemberIds.Add(memberId); return Task.FromResult(Latest); }
        public Task<ServiceResult<MemberMeasurementResponse>> CreateMeasurementAsync(long memberId, CreateMemberMeasurementRequest request)
        { MemberIds.Add(memberId); Request = request; return Task.FromResult(Create); }
    }
}
