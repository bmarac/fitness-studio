using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ClassSessionsControllerTests
{
    [Fact]
    public async Task GetClassSessionsReturnsServiceItems()
    {
        var from = new DateTime(2026, 10, 13, 12, 0, 0, DateTimeKind.Utc);
        var to = new DateTime(2026, 10, 19, 0, 0, 0, DateTimeKind.Utc);
        var sessions = new List<ClassSessionResponse> { Session() };
        var service = new FakeClassSessionsService { GetSessionsResult = sessions };
        var controller = new ClassSessionsController(service);

        var action = await controller.GetClassSessions(from, to);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(sessions, ok.Value);
        Assert.Equal(from, service.LastFrom);
        Assert.Equal(to, service.LastTo);
    }

    [Fact]
    public async Task GetClassSessionsRejectsInvalidRange()
    {
        var from = new DateTime(2026, 10, 19, 0, 0, 0, DateTimeKind.Utc);
        var controller = new ClassSessionsController(new FakeClassSessionsService());

        var action = await controller.GetClassSessions(from, from);

        Assert.IsType<BadRequestObjectResult>(action.Result);
    }

    [Fact]
    public async Task GetMyClassSessionsReturnsTrainerItems()
    {
        var sessions = new List<ClassSessionResponse> { Session() };
        var service = new FakeClassSessionsService { GetMySessionsResult = sessions };
        var controller = new ClassSessionsController(service);

        var action = await controller.GetMyClassSessions();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(sessions, ok.Value);
    }

    [Fact]
    public async Task GetWorkoutsReturnsPageAndForwardsQuery()
    {
        var query = new ClassSessionWorkoutsQuery
        {
            Filter = "completed",
            Page = 2,
            PageSize = 20,
            TrainerId = 8
        };
        var page = new ClassSessionWorkoutsPageResponse
        {
            Items = [Session()],
            Page = 2,
            PageSize = 20,
            HasNextPage = true
        };
        var service = new FakeClassSessionsService { GetWorkoutsResult = page };
        var controller = new ClassSessionsController(service);

        var action = await controller.GetWorkouts(query);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(page, ok.Value);
        Assert.Same(query, service.LastWorkoutsQuery);
    }

    [Fact]
    public async Task GetClassSessionReturnsItemAndForwardsId()
    {
        var session = Session();
        var service = new FakeClassSessionsService
        {
            GetSessionResult = ServiceResult<ClassSessionResponse>.Success(session)
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.GetClassSession(21);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(session, ok.Value);
        Assert.Equal(21, service.LastGetSessionId);
    }

    [Fact]
    public async Task GetClassSessionMapsNotFound()
    {
        var service = new FakeClassSessionsService
        {
            GetSessionResult = ServiceResult<ClassSessionResponse>.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.")
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.GetClassSession(404);

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task CreateClassSessionReturnsCreatedAtGetAndForwardsRequest()
    {
        var session = Session();
        var request = CreateRequest();
        var service = new FakeClassSessionsService
        {
            CreateSessionResult = ServiceResult<ClassSessionResponse>.Success(session)
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.CreateClassSession(request);

        var created = Assert.IsType<CreatedAtActionResult>(action.Result);
        Assert.Equal(nameof(ClassSessionsController.GetClassSession), created.ActionName);
        Assert.Equal(session.Id, created.RouteValues?["id"]);
        Assert.Same(session, created.Value);
        Assert.Same(request, service.LastCreateRequest);
    }

    [Fact]
    public async Task CreateClassSessionMapsConflict()
    {
        var service = new FakeClassSessionsService
        {
            CreateSessionResult = ServiceResult<ClassSessionResponse>.Conflict(
                "Class session conflict.",
                "The trainer already has a class session at this time.")
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.CreateClassSession(CreateRequest());

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task UpdateClassSessionReturnsNoContentAndForwardsArguments()
    {
        var request = UpdateRequest();
        var service = new FakeClassSessionsService { UpdateSessionResult = ServiceResult.Success() };
        var controller = new ClassSessionsController(service);

        var action = await controller.UpdateClassSession(21, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(21, service.LastUpdateSessionId);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task UpdateClassSessionMapsNotFound()
    {
        var service = new FakeClassSessionsService
        {
            UpdateSessionResult = ServiceResult.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.")
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.UpdateClassSession(404, UpdateRequest());

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task DeleteClassSessionReturnsNoContentAndForwardsId()
    {
        var service = new FakeClassSessionsService { DeleteSessionResult = ServiceResult.Success() };
        var controller = new ClassSessionsController(service);

        var action = await controller.DeleteClassSession(21);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(21, service.LastDeleteSessionId);
    }

    [Fact]
    public async Task DeleteClassSessionMapsConflict()
    {
        var service = new FakeClassSessionsService
        {
            DeleteSessionResult = ServiceResult.Conflict(
                "Class session cannot be deleted.",
                "The class session has active bookings.")
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.DeleteClassSession(21);

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task CancelClassSessionReturnsNoContentAndForwardsId()
    {
        var service = new FakeClassSessionsService { CancelSessionResult = ServiceResult.Success() };
        var controller = new ClassSessionsController(service);

        var action = await controller.CancelClassSession(21);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(21, service.LastCancelSessionId);
    }

    [Fact]
    public async Task CancelClassSessionMapsForbidden()
    {
        var service = new FakeClassSessionsService
        {
            CancelSessionResult = ServiceResult.Forbidden(
                "Class session cannot be cancelled.",
                "Access is denied.")
        };
        var controller = new ClassSessionsController(service);

        var action = await controller.CancelClassSession(21);

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status403Forbidden);
    }

    [Fact]
    public void AuthorizationRequiresTrainerAndStaffRolesWhereDeclared()
    {
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassSessionsController),
            nameof(ClassSessionsController.GetMyClassSessions),
            AuthRoles.Trainer);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassSessionsController),
            nameof(ClassSessionsController.GetWorkouts),
            AuthRoles.Staff);
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(ClassSessionsController),
            nameof(ClassSessionsController.CancelClassSession),
            AuthRoles.Staff);
    }

    private static ClassSessionResponse Session()
        => new()
        {
            Id = 21,
            ClassTypeId = 5,
            ClassTypeName = "Pilates",
            TrainerId = 8,
            TrainerFirstName = "Ivan",
            TrainerLastName = "Ivic",
            StartsAt = new DateTime(2026, 10, 13, 17, 0, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 10, 13, 18, 0, 0, DateTimeKind.Utc),
            Capacity = 12,
            BookedCount = 4,
            Status = "scheduled"
        };

    private static CreateClassSessionRequest CreateRequest()
        => new()
        {
            ClassTypeId = 5,
            TrainerId = 8,
            StartsAt = new DateTime(2026, 10, 13, 17, 0, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 10, 13, 18, 0, 0, DateTimeKind.Utc),
            Capacity = 12,
            Status = "scheduled"
        };

    private static UpdateClassSessionRequest UpdateRequest()
        => new()
        {
            ClassTypeId = 5,
            TrainerId = 8,
            StartsAt = new DateTime(2026, 10, 13, 17, 30, 0, DateTimeKind.Utc),
            EndsAt = new DateTime(2026, 10, 13, 18, 30, 0, DateTimeKind.Utc),
            Capacity = 14,
            Status = "scheduled"
        };

    private sealed class FakeClassSessionsService : IClassSessionsService
    {
        public List<ClassSessionResponse> GetSessionsResult { get; init; } = [];
        public List<ClassSessionResponse> GetMySessionsResult { get; init; } = [];
        public ClassSessionWorkoutsPageResponse GetWorkoutsResult { get; init; } = new();
        public ServiceResult<ClassSessionResponse> GetSessionResult { get; init; } = null!;
        public ServiceResult<ClassSessionResponse> CreateSessionResult { get; init; } = null!;
        public ServiceResult UpdateSessionResult { get; init; } = null!;
        public ServiceResult DeleteSessionResult { get; init; } = null!;
        public ServiceResult CancelSessionResult { get; init; } = null!;
        public long? LastGetSessionId { get; private set; }
        public DateTime? LastFrom { get; private set; }
        public DateTime? LastTo { get; private set; }
        public ClassSessionWorkoutsQuery? LastWorkoutsQuery { get; private set; }
        public CreateClassSessionRequest? LastCreateRequest { get; private set; }
        public long? LastUpdateSessionId { get; private set; }
        public UpdateClassSessionRequest? LastUpdateRequest { get; private set; }
        public long? LastDeleteSessionId { get; private set; }
        public long? LastCancelSessionId { get; private set; }

        public Task<List<ClassSessionResponse>> GetClassSessionsAsync(
            DateTime? from = null,
            DateTime? to = null)
        {
            LastFrom = from;
            LastTo = to;
            return Task.FromResult(GetSessionsResult);
        }

        public Task<List<ClassSessionResponse>> GetMyClassSessionsAsync()
            => Task.FromResult(GetMySessionsResult);

        public Task<ClassSessionWorkoutsPageResponse> GetWorkoutsAsync(
            ClassSessionWorkoutsQuery query)
        {
            LastWorkoutsQuery = query;
            return Task.FromResult(GetWorkoutsResult);
        }

        public Task<ServiceResult<ClassSessionResponse>> GetClassSessionAsync(long id)
        {
            LastGetSessionId = id;
            return Task.FromResult(GetSessionResult);
        }

        public Task<ServiceResult<ClassSessionResponse>> CreateClassSessionAsync(
            CreateClassSessionRequest request)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreateSessionResult);
        }

        public Task<ServiceResult> UpdateClassSessionAsync(
            long id,
            UpdateClassSessionRequest request)
        {
            LastUpdateSessionId = id;
            LastUpdateRequest = request;
            return Task.FromResult(UpdateSessionResult);
        }

        public Task<ServiceResult> CancelClassSessionAsync(long id)
        {
            LastCancelSessionId = id;
            return Task.FromResult(CancelSessionResult);
        }

        public Task<ServiceResult> DeleteClassSessionAsync(long id)
        {
            LastDeleteSessionId = id;
            return Task.FromResult(DeleteSessionResult);
        }
    }
}
