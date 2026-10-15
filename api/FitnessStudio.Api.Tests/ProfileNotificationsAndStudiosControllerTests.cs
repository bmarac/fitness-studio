using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Notifications;
using FitnessStudio.Api.Dtos.Profile;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ProfileNotificationsAndStudiosControllerTests
{
    [Fact]
    public async Task ProfileReturnsValueAndMapsFailure()
    {
        var response = Profile();
        var service = new FakeProfileService
        {
            Result = ServiceResult<ProfileResponse>.Success(response)
        };
        var controller = new ProfileController(service);

        Assert.Same(response, Assert.IsType<OkObjectResult>(
            (await controller.GetProfile()).Result).Value);

        service.Result = ServiceResult<ProfileResponse>.NotFound("Missing.", "Profile missing.");
        SchedulingControllerTestAssertions.Problem(
            (await controller.GetProfile()).Result, 404);
    }

    [Fact]
    public void ProfileRequiresAuthentication()
    {
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(typeof(ProfileController));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            typeof(ProfileController), nameof(ProfileController.GetProfile));
    }

    [Fact]
    public async Task StudioReturnsCurrentValueAndForwardsUpdate()
    {
        var studio = new StudioResponse(3, "Stay Fit", "Europe/Zagreb", "active");
        var service = new FakeStudiosService
        {
            GetResult = ServiceResult<StudioResponse>.Success(studio),
            UpdateResult = ServiceResult.Success()
        };
        var controller = new StudiosController(service);
        var request = new UpdateStudioRequest { Name = "New", Timezone = "Europe/Zagreb" };

        Assert.Same(studio, Assert.IsType<OkObjectResult>(
            (await controller.GetCurrentStudio()).Result).Value);
        Assert.IsType<NoContentResult>(await controller.UpdateCurrentStudio(request));
        Assert.Same(request, service.UpdateRequest);
    }

    [Fact]
    public async Task StudioMapsFailuresAndRequiresAdminForUpdate()
    {
        var service = new FakeStudiosService
        {
            GetResult = ServiceResult<StudioResponse>.NotFound("Missing.", "Studio missing."),
            UpdateResult = ServiceResult.Conflict("Conflict.", "Name exists.")
        };
        var controller = new StudiosController(service);

        SchedulingControllerTestAssertions.Problem(
            (await controller.GetCurrentStudio()).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            await controller.UpdateCurrentStudio(new UpdateStudioRequest()), 409);
        SchedulingControllerTestAssertions.ControllerRequiresAuthorization(typeof(StudiosController));
        SchedulingControllerTestAssertions.MethodHasNoRoleOverride(
            typeof(StudiosController), nameof(StudiosController.GetCurrentStudio));
        SchedulingControllerTestAssertions.MethodRequiresRole(
            typeof(StudiosController), nameof(StudiosController.UpdateCurrentStudio), AuthRoles.Admin);
    }

    [Fact]
    public async Task NotificationsAreOrderedAndIsolatedByUserAndStudio()
    {
        await using var db = Database();
        db.AppNotifications.AddRange(
            Notification(1, 7, 3, "older", new DateTime(2026, 1, 1, 8, 0, 0, DateTimeKind.Utc)),
            Notification(2, 7, 3, "newer", new DateTime(2026, 1, 2, 8, 0, 0, DateTimeKind.Utc)),
            Notification(3, 8, 3, "other user", DateTime.UtcNow),
            Notification(4, 7, 4, "other studio", DateTime.UtcNow));
        await db.SaveChangesAsync();
        var controller = new NotificationsController(db, new FakeCurrentUserContext(7, 3));

        var result = Assert.IsType<OkObjectResult>((await controller.Get()).Result);
        var notifications = Assert.IsType<List<AppNotificationResponse>>(result.Value);

        Assert.Equal([2L, 1L], notifications.Select(item => item.Id));
    }

    [Fact]
    public async Task ReadMarksOnlyOwnedStudioNotificationAndMissingReturnsNotFound()
    {
        await using var db = Database();
        db.AppNotifications.AddRange(
            Notification(1, 7, 3, "owned", DateTime.UtcNow),
            Notification(2, 8, 3, "other", DateTime.UtcNow));
        await db.SaveChangesAsync();
        var controller = new NotificationsController(db, new FakeCurrentUserContext(7, 3));

        Assert.IsType<NoContentResult>(await controller.Read(1));
        Assert.NotNull((await db.AppNotifications.FindAsync(1L))!.ReadAt);
        Assert.IsType<NotFoundResult>(await controller.Read(2));
        Assert.Null((await db.AppNotifications.FindAsync(2L))!.ReadAt);
    }

    [Fact]
    public async Task DeviceTokenRegistrationCreatesUpdatesAndUnregistersOwnedToken()
    {
        await using var db = Database();
        var controller = new NotificationsController(db, new FakeCurrentUserContext(7, 3));
        var request = new RegisterDeviceTokenRequest { Token = "device-a", Platform = "android" };

        Assert.IsType<NoContentResult>(await controller.Register(request));
        var token = Assert.Single(db.AppUserDeviceTokens);
        Assert.Equal(7, token.AppUserId);
        Assert.Equal("android", token.Platform);

        var otherController = new NotificationsController(db, new FakeCurrentUserContext(8, 4));
        Assert.IsType<NoContentResult>(await otherController.Register(
            new RegisterDeviceTokenRequest { Token = "device-a", Platform = "ios" }));
        Assert.Equal(8, token.AppUserId);
        Assert.Equal("ios", token.Platform);

        Assert.IsType<NoContentResult>(await controller.Unregister(request));
        Assert.Single(db.AppUserDeviceTokens);
        Assert.IsType<NoContentResult>(await otherController.Unregister(request));
        Assert.Empty(db.AppUserDeviceTokens);
    }

    [Fact]
    public void NotificationAuthorizationSeparatesStudioAndAccountTokens()
    {
        var type = typeof(NotificationsController);
        foreach (var method in new[]
        {
            nameof(NotificationsController.Get), nameof(NotificationsController.Read)
        })
        {
            var attribute = type.GetMethod(method)!.GetCustomAttribute<AuthorizeAttribute>();
            Assert.NotNull(attribute);
            Assert.Null(attribute.Policy);
        }
        foreach (var method in new[]
        {
            nameof(NotificationsController.Register), nameof(NotificationsController.Unregister)
        })
        {
            Assert.Equal("AccountAccess", type.GetMethod(method)!
                .GetCustomAttribute<AuthorizeAttribute>()?.Policy);
        }
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static AppNotification Notification(
        long id,
        long userId,
        long studioId,
        string title,
        DateTime createdAt) => new()
        {
            Id = id,
            AppUserId = userId,
            StudioId = studioId,
            NotificationType = "test",
            Title = title,
            Body = "Body",
            CreatedAt = createdAt
        };

    private static ProfileResponse Profile() => new(
        new ProfileUserResponse(7, "member@example.com", [AuthRoles.Member]),
        new StudioResponse(3, "Stay Fit", "Europe/Zagreb", "active"),
        null,
        null,
        null,
        null,
        []);

    private sealed class FakeProfileService : IProfileService
    {
        public ServiceResult<ProfileResponse> Result { get; set; } = null!;
        public Task<ServiceResult<ProfileResponse>> GetProfileAsync() => Task.FromResult(Result);
    }

    private sealed class FakeStudiosService : IStudiosService
    {
        public ServiceResult<StudioResponse> GetResult { get; init; } = null!;
        public ServiceResult UpdateResult { get; init; } = null!;
        public UpdateStudioRequest? UpdateRequest { get; private set; }

        public Task<ServiceResult<StudioResponse>> GetCurrentStudioAsync() =>
            Task.FromResult(GetResult);

        public Task<ServiceResult> UpdateCurrentStudioAsync(UpdateStudioRequest request)
        {
            UpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }
    }

    private sealed class FakeCurrentUserContext(long userId, long studioId) : ICurrentUserContext
    {
        public long UserId => userId;
        public string Email => "user@example.com";
        public long StudioId => studioId;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>();
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => false;
    }
}
