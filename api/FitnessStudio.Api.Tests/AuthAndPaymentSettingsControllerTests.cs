using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class AuthAndPaymentSettingsControllerTests
{
    [Fact]
    public async Task LoginReturnsSessionAndForwardsRequest()
    {
        var response = AccountSessionResponse();
        var service = new FakeAuthService
        {
            Result = ServiceResult<AccountSessionResponse>.Success(response)
        };
        var controller = new AuthController(service);
        var request = new LoginRequest
        {
            Email = "member@example.com",
            Password = "secret"
        };

        var action = await controller.Login(request);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(response, ok.Value);
        Assert.Same(request, service.LastRequest);
    }

    [Fact]
    public async Task LoginMapsUnauthorizedResult()
    {
        var service = new FakeAuthService
        {
            Result = ServiceResult<AccountSessionResponse>.Unauthorized(
                "Login failed.",
                "Email or password is incorrect.")
        };
        var controller = new AuthController(service);

        var action = await controller.Login(new LoginRequest());

        AssertProblem(action.Result, StatusCodes.Status401Unauthorized);
    }

    [Fact]
    public void LoginIsAnonymous()
    {
        var method = typeof(AuthController).GetMethod(nameof(AuthController.Login));

        Assert.NotNull(method?.GetCustomAttribute<AllowAnonymousAttribute>());
    }

    [Fact]
    public async Task RefreshAndLogoutForwardRefreshToken()
    {
        var response = AccountSessionResponse();
        var service = new FakeAuthService
        {
            Result = ServiceResult<AccountSessionResponse>.Success(response)
        };
        var controller = new AuthController(service);

        var refresh = await controller.Refresh(new RefreshTokenRequest { RefreshToken = "refresh-token" });
        var logout = await controller.Logout(new RefreshTokenRequest { RefreshToken = "refresh-token" });

        Assert.Same(response, Assert.IsType<OkObjectResult>(refresh.Result).Value);
        Assert.Equal("refresh-token", service.LastRefreshToken);
        Assert.IsType<NoContentResult>(logout);
        Assert.Equal("refresh-token", service.LastLogoutToken);
    }

    [Theory]
    [InlineData(nameof(AuthController.Refresh))]
    [InlineData(nameof(AuthController.Logout))]
    public void RefreshSessionEndpointsAreAnonymous(string methodName)
    {
        var method = typeof(AuthController).GetMethod(methodName);

        Assert.NotNull(method?.GetCustomAttribute<AllowAnonymousAttribute>());
    }

    [Fact]
    public async Task PaymentSettingsGetReturnsServiceResponse()
    {
        var response = PaymentSettingsResponse();
        var service = new FakePaymentSettingsService { GetResult = response };
        var controller = new PaymentSettingsController(service);

        var action = await controller.Get();

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(response, ok.Value);
        Assert.Null(service.LastGetStudioId);
    }

    [Fact]
    public async Task PaymentSettingsUpdateReturnsResponseAndForwardsRequest()
    {
        var response = PaymentSettingsResponse();
        var service = new FakePaymentSettingsService
        {
            UpdateResult = ServiceResult<PaymentSettingsResponse>.Success(response)
        };
        var controller = new PaymentSettingsController(service);
        var request = new UpdatePaymentSettingsRequest();

        var action = await controller.Update(request);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(response, ok.Value);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task PaymentSettingsUpdateMapsConflict()
    {
        var service = new FakePaymentSettingsService
        {
            UpdateResult = ServiceResult<PaymentSettingsResponse>.Conflict(
                "Invalid settings",
                "Payment settings are incomplete.")
        };
        var controller = new PaymentSettingsController(service);

        var action = await controller.Update(new UpdatePaymentSettingsRequest());

        AssertProblem(action.Result, StatusCodes.Status409Conflict);
    }

    [Fact]
    public void PaymentSettingsRequiresAdminRole()
    {
        Assert.NotNull(typeof(PaymentSettingsController).GetCustomAttribute<AuthorizeAttribute>());
        AssertAdminMethod(typeof(PaymentSettingsController), nameof(PaymentSettingsController.Get));
        AssertAdminMethod(typeof(PaymentSettingsController), nameof(PaymentSettingsController.Update));
    }

    private static AccountSessionResponse AccountSessionResponse()
    {
        return new AccountSessionResponse(
            "access-token",
            new DateTime(2026, 10, 12, 12, 0, 0, DateTimeKind.Utc),
            "refresh-token",
            new DateTime(2026, 11, 11, 12, 0, 0, DateTimeKind.Utc),
            new AccountUserResponse(42, "member@example.com"),
            [new AccountStudioResponse(7, "Stay Fit", 11, null, [AuthRoles.Member])]);
    }

    private static PaymentSettingsResponse PaymentSettingsResponse()
    {
        return new PaymentSettingsResponse(
            "Fitness Studio",
            "HR1723600001101234565",
            "HR00",
            "123",
            "Membership fee",
            [0, 1],
            [2],
            new TimeOnly(9, 0),
            true);
    }

    private static void AssertAdminMethod(Type controllerType, string methodName)
    {
        var attribute = controllerType
            .GetMethod(methodName)!
            .GetCustomAttribute<AuthorizeAttribute>();
        Assert.Equal(AuthRoles.Admin, attribute?.Roles);
    }

    private static void AssertProblem(ActionResult? action, int statusCode)
    {
        var objectResult = Assert.IsType<ObjectResult>(action);
        Assert.Equal(statusCode, objectResult.StatusCode);
        Assert.Equal(statusCode, Assert.IsType<ProblemDetails>(objectResult.Value).Status);
    }

    private sealed class FakeAuthService : IAuthService
    {
        public ServiceResult<AccountSessionResponse> Result { get; init; } = null!;
        public LoginRequest? LastRequest { get; private set; }
        public string? LastRefreshToken { get; private set; }
        public string? LastLogoutToken { get; private set; }

        public Task<ServiceResult<AccountSessionResponse>> LoginAsync(LoginRequest request)
        {
            LastRequest = request;
            return Task.FromResult(Result);
        }

        public Task<ServiceResult<AccountSessionResponse>> RegisterAsync(RegisterRequest request) =>
            Task.FromResult(Result);

        public Task<ServiceResult<AccountSessionResponse>> RefreshAsync(string refreshToken)
        {
            LastRefreshToken = refreshToken;
            return Task.FromResult(Result);
        }

        public Task LogoutAsync(string refreshToken)
        {
            LastLogoutToken = refreshToken;
            return Task.CompletedTask;
        }

        public Task<ServiceResult<LoginResponse>> CreateStudioSessionAsync(long userId, long studioId) =>
            Task.FromResult(ServiceResult<LoginResponse>.Forbidden("Denied", "Denied"));
    }

    private sealed class FakePaymentSettingsService : IPaymentSettingsService
    {
        public PaymentSettingsResponse GetResult { get; init; } = null!;
        public ServiceResult<PaymentSettingsResponse> UpdateResult { get; init; } = null!;
        public long? LastGetStudioId { get; private set; }
        public UpdatePaymentSettingsRequest? LastUpdateRequest { get; private set; }

        public Task<PaymentSettingsResponse> GetAsync(long? studioId = null)
        {
            LastGetStudioId = studioId;
            return Task.FromResult(GetResult);
        }

        public Task<ServiceResult<PaymentSettingsResponse>> UpdateAsync(
            UpdatePaymentSettingsRequest request)
        {
            LastUpdateRequest = request;
            return Task.FromResult(UpdateResult);
        }
    }
}
