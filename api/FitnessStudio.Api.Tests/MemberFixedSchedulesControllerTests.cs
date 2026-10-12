using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberFixedSchedulesControllerTests
{
    [Fact]
    public async Task GetSchedulesReturnsServiceItems()
    {
        var schedules = new List<MemberFixedScheduleResponse> { Schedule() };
        var service = new FakeMemberFixedSchedulesService { GetSchedulesResult = schedules };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.GetSchedules();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(schedules, ok.Value);
    }

    [Fact]
    public async Task GetScheduleReturnsItemAndForwardsId()
    {
        var schedule = Schedule();
        var service = new FakeMemberFixedSchedulesService
        {
            GetScheduleResult = ServiceResult<MemberFixedScheduleResponse>.Success(schedule)
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.GetSchedule(51);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(schedule, ok.Value);
        Assert.Equal(51, service.LastGetScheduleId);
    }

    [Fact]
    public async Task GetScheduleMapsNotFound()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            GetScheduleResult = ServiceResult<MemberFixedScheduleResponse>.NotFound(
                "Fixed schedule not found.",
                "A fixed schedule with this id does not exist.")
        };
        var controller = new MemberFixedSchedulesController(service);

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
        var service = new FakeMemberFixedSchedulesService
        {
            CreateScheduleResult = ServiceResult<MemberFixedScheduleResponse>.Success(schedule)
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.CreateSchedule(request);

        var created = Assert.IsType<CreatedAtActionResult>(action.Result);
        Assert.Equal(nameof(MemberFixedSchedulesController.GetSchedule), created.ActionName);
        Assert.Equal(schedule.Id, created.RouteValues?["id"]);
        Assert.Same(schedule, created.Value);
        Assert.Same(request, service.LastCreateRequest);
    }

    [Fact]
    public async Task CreateScheduleMapsConflict()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            CreateScheduleResult = ServiceResult<MemberFixedScheduleResponse>.Conflict(
                "Fixed schedule conflict.",
                "The member already has this schedule.")
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.CreateSchedule(CreateRequest());

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task UpdateScheduleReturnsNoContentAndForwardsArguments()
    {
        var request = UpdateRequest();
        var service = new FakeMemberFixedSchedulesService
        {
            UpdateScheduleResult = ServiceResult.Success()
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.UpdateSchedule(51, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(51, service.LastUpdateScheduleId);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task UpdateScheduleMapsNotFound()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            UpdateScheduleResult = ServiceResult.NotFound(
                "Fixed schedule not found.",
                "A fixed schedule with this id does not exist.")
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.UpdateSchedule(404, UpdateRequest());

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task CancelScheduleReturnsNoContentAndForwardsEffectiveDate()
    {
        var request = new CancelMemberFixedScheduleRequest
        {
            EffectiveFrom = new DateOnly(2026, 10, 19)
        };
        var service = new FakeMemberFixedSchedulesService
        {
            CancelScheduleResult = ServiceResult.Success()
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.CancelSchedule(51, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(51, service.LastCancelScheduleId);
        Assert.Same(request, service.LastCancelRequest);
        Assert.Equal(new DateOnly(2026, 10, 19), service.LastCancelRequest?.EffectiveFrom);
    }

    [Fact]
    public async Task CancelScheduleMapsForbidden()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            CancelScheduleResult = ServiceResult.Forbidden(
                "Fixed schedule cannot be cancelled.",
                "Access is denied.")
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.CancelSchedule(
            51,
            new CancelMemberFixedScheduleRequest());

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status403Forbidden);
    }

    [Fact]
    public async Task DeleteScheduleReturnsNoContentAndForwardsId()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            DeleteScheduleResult = ServiceResult.Success()
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.DeleteSchedule(51);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(51, service.LastDeleteScheduleId);
    }

    [Fact]
    public async Task DeleteScheduleMapsConflict()
    {
        var service = new FakeMemberFixedSchedulesService
        {
            DeleteScheduleResult = ServiceResult.Conflict(
                "Fixed schedule cannot be deleted.",
                "The schedule has generated bookings.")
        };
        var controller = new MemberFixedSchedulesController(service);

        var action = await controller.DeleteSchedule(51);

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public void AuthorizationSeparatesReadsAdminChangesAndStaffCancellation()
    {
        var type = typeof(MemberFixedSchedulesController);
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(type);
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type,
            nameof(MemberFixedSchedulesController.GetSchedules));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            type,
            nameof(MemberFixedSchedulesController.GetSchedule));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(MemberFixedSchedulesController.CreateSchedule),
            AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(MemberFixedSchedulesController.UpdateSchedule),
            AuthRoles.Admin);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(MemberFixedSchedulesController.CancelSchedule),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            type,
            nameof(MemberFixedSchedulesController.DeleteSchedule),
            AuthRoles.Admin);
    }

    private static MemberFixedScheduleResponse Schedule()
        => new(
            51,
            11,
            "Ana Horvat",
            41,
            "Pilates",
            "Ivan Ivic",
            1,
            new TimeOnly(17, 0),
            new DateOnly(2026, 10, 12),
            null,
            "active");

    private static CreateMemberFixedScheduleRequest CreateRequest()
        => new()
        {
            MemberId = 11,
            RecurringScheduleId = 41,
            StartsOn = new DateOnly(2026, 10, 12),
            Status = "active"
        };

    private static UpdateMemberFixedScheduleRequest UpdateRequest()
        => new()
        {
            MemberId = 11,
            RecurringScheduleId = 41,
            StartsOn = new DateOnly(2026, 10, 19),
            Status = "active"
        };

    private sealed class FakeMemberFixedSchedulesService : IMemberFixedSchedulesService
    {
        public List<MemberFixedScheduleResponse> GetSchedulesResult { get; init; } = [];
        public ServiceResult<MemberFixedScheduleResponse> GetScheduleResult { get; init; } = null!;
        public ServiceResult<MemberFixedScheduleResponse> CreateScheduleResult { get; init; } = null!;
        public ServiceResult UpdateScheduleResult { get; init; } = null!;
        public ServiceResult CancelScheduleResult { get; init; } = null!;
        public ServiceResult DeleteScheduleResult { get; init; } = null!;
        public long? LastGetScheduleId { get; private set; }
        public CreateMemberFixedScheduleRequest? LastCreateRequest { get; private set; }
        public long? LastUpdateScheduleId { get; private set; }
        public UpdateMemberFixedScheduleRequest? LastUpdateRequest { get; private set; }
        public long? LastCancelScheduleId { get; private set; }
        public CancelMemberFixedScheduleRequest? LastCancelRequest { get; private set; }
        public long? LastDeleteScheduleId { get; private set; }

        public Task<List<MemberFixedScheduleResponse>> GetSchedulesAsync()
            => Task.FromResult(GetSchedulesResult);

        public Task<List<MemberFixedScheduleResponse>> GetCurrentMemberSchedulesAsync()
            => Task.FromResult(GetSchedulesResult);

        public Task<ServiceResult<MemberFixedScheduleResponse>> GetScheduleAsync(long id)
        {
            LastGetScheduleId = id;
            return Task.FromResult(GetScheduleResult);
        }

        public Task<ServiceResult<MemberFixedScheduleResponse>> CreateScheduleAsync(
            CreateMemberFixedScheduleRequest request)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreateScheduleResult);
        }

        public Task<ServiceResult> UpdateScheduleAsync(
            long id,
            UpdateMemberFixedScheduleRequest request)
        {
            LastUpdateScheduleId = id;
            LastUpdateRequest = request;
            return Task.FromResult(UpdateScheduleResult);
        }

        public Task<ServiceResult> CancelScheduleAsync(
            long id,
            CancelMemberFixedScheduleRequest request)
        {
            LastCancelScheduleId = id;
            LastCancelRequest = request;
            return Task.FromResult(CancelScheduleResult);
        }

        public Task<ServiceResult> DeleteScheduleAsync(long id)
        {
            LastDeleteScheduleId = id;
            return Task.FromResult(DeleteScheduleResult);
        }
    }
}
