using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.RecurringClassSchedules;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class RecurringClassSchedulesControllerTests
{
    [Fact]
    public async Task GetSchedulesReturnsServiceItems()
    {
        var schedules = new List<RecurringClassScheduleResponse> { Schedule() };
        var service = new FakeRecurringClassSchedulesService { GetSchedulesResult = schedules };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.GetSchedules();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(schedules, ok.Value);
    }

    [Fact]
    public async Task GetScheduleReturnsItemAndForwardsId()
    {
        var schedule = Schedule();
        var service = new FakeRecurringClassSchedulesService
        {
            GetScheduleResult = ServiceResult<RecurringClassScheduleResponse>.Success(schedule)
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.GetSchedule(41);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(schedule, ok.Value);
        Assert.Equal(41, service.LastGetScheduleId);
    }

    [Fact]
    public async Task GetScheduleMapsNotFound()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            GetScheduleResult = ServiceResult<RecurringClassScheduleResponse>.NotFound(
                "Schedule not found.",
                "A recurring schedule with this id does not exist.")
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.GetSchedule(404);

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task CreateScheduleReturnsCreatedAtGetAndForwardsRequest()
    {
        var schedule = Schedule();
        var request = CreateRequest();
        var service = new FakeRecurringClassSchedulesService
        {
            CreateScheduleResult = ServiceResult<RecurringClassScheduleResponse>.Success(schedule)
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.CreateSchedule(request);

        var created = Assert.IsType<CreatedAtActionResult>(action.Result);
        Assert.Equal(nameof(RecurringClassSchedulesController.GetSchedule), created.ActionName);
        Assert.Equal(schedule.Id, created.RouteValues?["id"]);
        Assert.Same(schedule, created.Value);
        Assert.Same(request, service.LastCreateRequest);
    }

    [Fact]
    public async Task CreateScheduleMapsConflict()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            CreateScheduleResult = ServiceResult<RecurringClassScheduleResponse>.Conflict(
                "Schedule conflict.",
                "The trainer already has a recurring schedule at this time.")
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.CreateSchedule(CreateRequest());

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task UpdateScheduleReturnsNoContentAndForwardsArguments()
    {
        var request = UpdateRequest();
        var service = new FakeRecurringClassSchedulesService
        {
            UpdateScheduleResult = ServiceResult.Success()
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.UpdateSchedule(41, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(41, service.LastUpdateScheduleId);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task UpdateScheduleMapsNotFound()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            UpdateScheduleResult = ServiceResult.NotFound(
                "Schedule not found.",
                "A recurring schedule with this id does not exist.")
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.UpdateSchedule(404, UpdateRequest());

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task LifecycleActionsReturnNoContentAndForwardEffectiveDates()
    {
        var pause = ChangeRequest(new DateOnly(2026, 10, 19));
        var resume = ChangeRequest(new DateOnly(2026, 10, 26));
        var end = ChangeRequest(new DateOnly(2026, 11, 2));
        var service = new FakeRecurringClassSchedulesService
        {
            PauseResult = ServiceResult.Success(),
            ResumeResult = ServiceResult.Success(),
            EndResult = ServiceResult.Success()
        };
        var controller = new RecurringClassSchedulesController(service);

        Assert.IsType<NoContentResult>(await controller.PauseSchedule(41, pause));
        Assert.IsType<NoContentResult>(await controller.ResumeSchedule(42, resume));
        Assert.IsType<NoContentResult>(await controller.EndSchedule(43, end));

        Assert.Equal(41, service.LastPauseId);
        Assert.Same(pause, service.LastPauseRequest);
        Assert.Equal(42, service.LastResumeId);
        Assert.Same(resume, service.LastResumeRequest);
        Assert.Equal(43, service.LastEndId);
        Assert.Same(end, service.LastEndRequest);
    }

    [Fact]
    public async Task LifecycleActionsMapServiceFailures()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            PauseResult = ServiceResult.Conflict("Cannot pause.", "The date is invalid."),
            ResumeResult = ServiceResult.NotFound("Schedule not found.", "Missing schedule."),
            EndResult = ServiceResult.Forbidden("Cannot end.", "Access is denied.")
        };
        var controller = new RecurringClassSchedulesController(service);
        var request = ChangeRequest(new DateOnly(2026, 10, 19));

        SchedulingControllerTestAssertions.Problem(
            await controller.PauseSchedule(41, request),
            StatusCodes.Status409Conflict);
        SchedulingControllerTestAssertions.Problem(
            await controller.ResumeSchedule(41, request),
            StatusCodes.Status404NotFound);
        SchedulingControllerTestAssertions.Problem(
            await controller.EndSchedule(41, request),
            StatusCodes.Status403Forbidden);
    }

    [Fact]
    public async Task DeleteScheduleReturnsNoContentAndForwardsId()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            DeleteScheduleResult = ServiceResult.Success()
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.DeleteSchedule(41);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(41, service.LastDeleteScheduleId);
    }

    [Fact]
    public async Task DeleteScheduleMapsConflict()
    {
        var service = new FakeRecurringClassSchedulesService
        {
            DeleteScheduleResult = ServiceResult.Conflict(
                "Schedule cannot be deleted.",
                "The schedule has generated sessions.")
        };
        var controller = new RecurringClassSchedulesController(service);

        var action = await controller.DeleteSchedule(41);

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public void AuthorizationSeparatesReadsAdminChangesAndStaffLifecycleActions()
    {
        var type = typeof(RecurringClassSchedulesController);
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(type);
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type,
            nameof(RecurringClassSchedulesController.GetSchedules));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type,
            nameof(RecurringClassSchedulesController.GetSchedule));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.CreateSchedule),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.UpdateSchedule),
            AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.PauseSchedule),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.ResumeSchedule),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.EndSchedule),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(RecurringClassSchedulesController.DeleteSchedule),
            AuthRoles.Admin);
    }

    private static RecurringClassScheduleResponse Schedule()
        => new(
            41,
            5,
            "Pilates",
            8,
            "Ivan Ivic",
            1,
            new TimeOnly(17, 0),
            60,
            12,
            new DateOnly(2026, 10, 12),
            null,
            "active",
            null);

    private static CreateRecurringClassScheduleRequest CreateRequest()
        => new()
        {
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(17, 0),
            DurationMinutes = 60,
            Capacity = 12,
            ValidFrom = new DateOnly(2026, 10, 12),
            Status = "active"
        };

    private static UpdateRecurringClassScheduleRequest UpdateRequest()
        => new()
        {
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(17, 30),
            DurationMinutes = 60,
            Capacity = 14,
            ValidFrom = new DateOnly(2026, 10, 12),
            Status = "active"
        };

    private static ChangeRecurringClassScheduleStatusRequest ChangeRequest(DateOnly date)
        => new() { EffectiveFrom = date };

    private sealed class FakeRecurringClassSchedulesService : IRecurringClassSchedulesService
    {
        public List<RecurringClassScheduleResponse> GetSchedulesResult { get; init; } = [];
        public ServiceResult<RecurringClassScheduleResponse> GetScheduleResult { get; init; } = null!;
        public ServiceResult<RecurringClassScheduleResponse> CreateScheduleResult { get; init; } = null!;
        public ServiceResult UpdateScheduleResult { get; init; } = null!;
        public ServiceResult PauseResult { get; init; } = null!;
        public ServiceResult ResumeResult { get; init; } = null!;
        public ServiceResult EndResult { get; init; } = null!;
        public ServiceResult DeleteScheduleResult { get; init; } = null!;
        public long? LastGetScheduleId { get; private set; }
        public CreateRecurringClassScheduleRequest? LastCreateRequest { get; private set; }
        public long? LastUpdateScheduleId { get; private set; }
        public UpdateRecurringClassScheduleRequest? LastUpdateRequest { get; private set; }
        public long? LastPauseId { get; private set; }
        public ChangeRecurringClassScheduleStatusRequest? LastPauseRequest { get; private set; }
        public long? LastResumeId { get; private set; }
        public ChangeRecurringClassScheduleStatusRequest? LastResumeRequest { get; private set; }
        public long? LastEndId { get; private set; }
        public ChangeRecurringClassScheduleStatusRequest? LastEndRequest { get; private set; }
        public long? LastDeleteScheduleId { get; private set; }

        public Task<List<RecurringClassScheduleResponse>> GetSchedulesAsync()
            => Task.FromResult(GetSchedulesResult);

        public Task<ServiceResult<RecurringClassScheduleResponse>> GetScheduleAsync(long id)
        {
            LastGetScheduleId = id;
            return Task.FromResult(GetScheduleResult);
        }

        public Task<ServiceResult<RecurringClassScheduleResponse>> CreateScheduleAsync(
            CreateRecurringClassScheduleRequest request)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreateScheduleResult);
        }

        public Task<ServiceResult> UpdateScheduleAsync(
            long id,
            UpdateRecurringClassScheduleRequest request)
        {
            LastUpdateScheduleId = id;
            LastUpdateRequest = request;
            return Task.FromResult(UpdateScheduleResult);
        }

        public Task<ServiceResult> PauseScheduleAsync(
            long id,
            ChangeRecurringClassScheduleStatusRequest request)
        {
            LastPauseId = id;
            LastPauseRequest = request;
            return Task.FromResult(PauseResult);
        }

        public Task<ServiceResult> ResumeScheduleAsync(
            long id,
            ChangeRecurringClassScheduleStatusRequest request)
        {
            LastResumeId = id;
            LastResumeRequest = request;
            return Task.FromResult(ResumeResult);
        }

        public Task<ServiceResult> EndScheduleAsync(
            long id,
            ChangeRecurringClassScheduleStatusRequest request)
        {
            LastEndId = id;
            LastEndRequest = request;
            return Task.FromResult(EndResult);
        }

        public Task<ServiceResult> DeleteScheduleAsync(long id)
        {
            LastDeleteScheduleId = id;
            return Task.FromResult(DeleteScheduleResult);
        }
    }
}
