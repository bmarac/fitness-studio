using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Validation;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class TrainersControllerAndValidationTests
{
    [Fact]
    public async Task ControllerMapsSuccessfulCrudAndForwardsArguments()
    {
        var trainer = Trainer();
        var service = new FakeService
        {
            ListResult = [trainer],
            GetResult = ServiceResult<TrainerResponse>.Success(trainer),
            CreateResult = ServiceResult<TrainerResponse>.Success(trainer),
            UpdateResult = ServiceResult.Success(),
            DeleteResult = ServiceResult.Success()
        };
        var controller = new TrainersController(service);
        var create = new CreateTrainerRequest();
        var update = new UpdateTrainerRequest();

        Assert.Same(service.ListResult, Assert.IsType<OkObjectResult>(
            (await controller.GetTrainers()).Result).Value);
        Assert.Same(trainer, Assert.IsType<OkObjectResult>(
            (await controller.GetTrainer(7)).Result).Value);
        var created = Assert.IsType<CreatedAtActionResult>(
            (await controller.CreateTrainer(create)).Result);
        Assert.Equal(nameof(TrainersController.GetTrainer), created.ActionName);
        Assert.Equal(17L, created.RouteValues!["id"]);
        Assert.Same(trainer, created.Value);
        Assert.IsType<NoContentResult>(await controller.UpdateTrainer(8, update));
        Assert.IsType<NoContentResult>(await controller.DeleteTrainer(9));
        Assert.Equal([7, 8, 9], service.Ids);
        Assert.Same(create, service.CreateRequest);
        Assert.Same(update, service.UpdateRequest);
    }

    [Fact]
    public async Task ControllerMapsNotFoundAndConflictFailures()
    {
        var service = new FakeService
        {
            GetResult = ServiceResult<TrainerResponse>.NotFound("Missing.", "Missing."),
            CreateResult = ServiceResult<TrainerResponse>.Conflict("Duplicate.", "Email exists."),
            UpdateResult = ServiceResult.NotFound("Missing.", "Missing."),
            DeleteResult = ServiceResult.Conflict("Used.", "Schedules exist.")
        };
        var controller = new TrainersController(service);

        SchedulingControllerTestAssertions.Problem((await controller.GetTrainer(1)).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.CreateTrainer(new CreateTrainerRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateTrainer(1, new UpdateTrainerRequest()), 404);
        SchedulingControllerTestAssertions.Problem(await controller.DeleteTrainer(1), 409);
    }

    [Fact]
    public void WritesRequireAdminWhileReadsUseGlobalFallbackPolicy()
    {
        var type = typeof(TrainersController);
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type, nameof(TrainersController.GetTrainers));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type, nameof(TrainersController.GetTrainer));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type, nameof(TrainersController.CreateTrainer), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type, nameof(TrainersController.UpdateTrainer), AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type, nameof(TrainersController.DeleteTrainer), AuthRoles.Admin);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("active")]
    [InlineData("INACTIVE")]
    public void TrainerStatusValidatorAcceptsSupportedValues(string? value)
    {
        var result = new AllowedTrainerStatusAttribute().GetValidationResult(
            value, new ValidationContext(new object()));

        Assert.Equal(ValidationResult.Success, result);
    }

    [Fact]
    public void TrainerStatusValidatorRejectsUnknownValueWithAllowedList()
    {
        var result = new AllowedTrainerStatusAttribute().GetValidationResult(
            "blocked", new ValidationContext(new object()));

        Assert.Contains("active", result!.ErrorMessage);
        Assert.Contains("inactive", result.ErrorMessage);
    }

    private static TrainerResponse Trainer() => new()
    {
        Id = 17,
        FirstName = "Filip",
        LastName = "Šarić",
        Email = "filip@example.com",
        Status = "active"
    };

    private sealed class FakeService : ITrainersService
    {
        public List<TrainerResponse> ListResult { get; init; } = [];
        public ServiceResult<TrainerResponse> GetResult { get; init; } = null!;
        public ServiceResult<TrainerResponse> CreateResult { get; init; } = null!;
        public ServiceResult UpdateResult { get; init; } = null!;
        public ServiceResult DeleteResult { get; init; } = null!;
        public List<long> Ids { get; } = [];
        public CreateTrainerRequest? CreateRequest { get; private set; }
        public UpdateTrainerRequest? UpdateRequest { get; private set; }

        public Task<List<TrainerResponse>> GetTrainersAsync() => Task.FromResult(ListResult);

        public Task<ServiceResult<TrainerResponse>> GetTrainerAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(GetResult);
        }

        public Task<ServiceResult<TrainerResponse>> CreateTrainerAsync(CreateTrainerRequest request)
        {
            CreateRequest = request;
            return Task.FromResult(CreateResult);
        }

        public Task<ServiceResult> UpdateTrainerAsync(long id, UpdateTrainerRequest request)
        {
            Ids.Add(id);
            UpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }

        public Task<ServiceResult> DeleteTrainerAsync(long id)
        {
            Ids.Add(id);
            return Task.FromResult(DeleteResult);
        }
    }
}
