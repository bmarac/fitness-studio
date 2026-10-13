using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.ClassTypes;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Validation;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ClassTypesControllerAndValidationTests
{
    [Fact]
    public async Task ControllerMapsSuccessfulCrudAndForwardsArguments()
    {
        var response = Response();
        var service = new FakeService
        {
            ListResult = [response],
            GetResult = ServiceResult<ClassTypeResponse>.Success(response),
            CreateResult = ServiceResult<ClassTypeResponse>.Success(response),
            UpdateResult = ServiceResult.Success(),
            DeleteResult = ServiceResult.Success()
        };
        var controller = new ClassTypesController(service);
        var create = new CreateClassTypeRequest();
        var update = new UpdateClassTypeRequest();

        Assert.Same(service.ListResult, Assert.IsType<OkObjectResult>(
            (await controller.GetClassTypes()).Result).Value);
        Assert.Same(response, Assert.IsType<OkObjectResult>(
            (await controller.GetClassType(7)).Result).Value);
        var created = Assert.IsType<CreatedAtActionResult>(
            (await controller.CreateClassType(create)).Result);
        Assert.Equal(nameof(ClassTypesController.GetClassType), created.ActionName);
        Assert.Equal(11L, created.RouteValues!["id"]);
        Assert.Same(response, created.Value);
        Assert.IsType<NoContentResult>(await controller.UpdateClassType(8, update));
        Assert.IsType<NoContentResult>(await controller.DeleteClassType(9));
        Assert.Equal([7, 8, 9], service.Ids);
        Assert.Same(create, service.CreateRequest);
        Assert.Same(update, service.UpdateRequest);
    }

    [Fact]
    public async Task ControllerMapsNotFoundAndConflictResponses()
    {
        var service = new FakeService
        {
            GetResult = ServiceResult<ClassTypeResponse>.NotFound("missing", "detail"),
            CreateResult = ServiceResult<ClassTypeResponse>.Conflict("duplicate", "detail"),
            UpdateResult = ServiceResult.NotFound("missing", "detail"),
            DeleteResult = ServiceResult.Conflict("assigned", "detail")
        };
        var controller = new ClassTypesController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetClassType(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.CreateClassType(new CreateClassTypeRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateClassType(1, new UpdateClassTypeRequest()), 404);
        SchedulingControllerTestAssertions.Problem(await controller.DeleteClassType(1), 409);
    }

    [Fact]
    public void AuthorizationAllowsAuthenticatedReadsAndRequiresAdminForWrites()
    {
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(
            typeof(ClassTypesController));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            typeof(ClassTypesController), nameof(ClassTypesController.GetClassTypes));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            typeof(ClassTypesController), nameof(ClassTypesController.GetClassType));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassTypesController), nameof(ClassTypesController.CreateClassType), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassTypesController), nameof(ClassTypesController.UpdateClassType), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassTypesController), nameof(ClassTypesController.DeleteClassType), AuthRoles.Admin);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("beginner")]
    [InlineData("ADVANCED")]
    [InlineData("all_levels")]
    public void DifficultyValidatorAcceptsSupportedValues(string? value)
    {
        var result = new AllowedClassTypeDifficultyLevelAttribute()
            .GetValidationResult(value, ValidationContext());

        Assert.Equal(ValidationResult.Success, result);
    }

    [Fact]
    public void DifficultyValidatorRejectsUnknownValuesWithAllowedList()
    {
        var result = new AllowedClassTypeDifficultyLevelAttribute()
            .GetValidationResult("expert", ValidationContext());

        Assert.Contains("beginner", result!.ErrorMessage);
        Assert.Contains("all_levels", result.ErrorMessage);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("active")]
    [InlineData("INACTIVE")]
    public void StatusValidatorAcceptsSupportedValues(string? value)
    {
        var result = new AllowedClassTypeStatusAttribute()
            .GetValidationResult(value, ValidationContext());

        Assert.Equal(ValidationResult.Success, result);
    }

    [Fact]
    public void StatusValidatorRejectsUnknownValuesWithAllowedList()
    {
        var result = new AllowedClassTypeStatusAttribute()
            .GetValidationResult("archived", ValidationContext());

        Assert.Contains("active", result!.ErrorMessage);
        Assert.Contains("inactive", result.ErrorMessage);
    }

    private static ValidationContext ValidationContext() => new(new object());

    private static ClassTypeResponse Response() => new()
    {
        Id = 11,
        Name = "Pilates",
        DefaultDurationMinutes = 60,
        DefaultCapacity = 10,
        DifficultyLevel = "all_levels",
        Status = "active"
    };

    private sealed class FakeService : IClassTypesService
    {
        public List<ClassTypeResponse> ListResult { get; init; } = [];
        public ServiceResult<ClassTypeResponse> GetResult { get; init; } = null!;
        public ServiceResult<ClassTypeResponse> CreateResult { get; init; } = null!;
        public ServiceResult UpdateResult { get; init; } = null!;
        public ServiceResult DeleteResult { get; init; } = null!;
        public List<long> Ids { get; } = [];
        public CreateClassTypeRequest? CreateRequest { get; private set; }
        public UpdateClassTypeRequest? UpdateRequest { get; private set; }

        public Task<List<ClassTypeResponse>> GetClassTypesAsync() => Task.FromResult(ListResult);

        public Task<ServiceResult<ClassTypeResponse>> GetClassTypeAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(GetResult);
        }

        public Task<ServiceResult<ClassTypeResponse>> CreateClassTypeAsync(
            CreateClassTypeRequest request)
        {
            CreateRequest = request;
            return Task.FromResult(CreateResult);
        }

        public Task<ServiceResult> UpdateClassTypeAsync(
            long id,
            UpdateClassTypeRequest request)
        {
            Ids.Add(id);
            UpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }

        public Task<ServiceResult> DeleteClassTypeAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(DeleteResult);
        }
    }
}
