using System.Reflection;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class AccountStudiosControllerTests
{
    [Fact]
    public async Task SuccessfulActionsReturnResponsesAndForwardArguments()
    {
        var studio = StudioResponse();
        var lookup = new StudioLookupResponse(7, "Stay Fit", true, AuthRoles.Member);
        var session = LoginResponse();
        var studios = new FakeAccountStudiosService
        {
            GetResult = [studio],
            LookupResult = ServiceResult<StudioLookupResponse>.Success(lookup),
            JoinResult = ServiceResult<AccountStudioResponse>.Success(studio)
        };
        var auth = new FakeAuthService
        {
            SelectResult = ServiceResult<LoginResponse>.Success(session)
        };
        var controller = new AccountStudiosController(
            studios, auth, new FakeCurrentUserContext(42));
        var lookupRequest = new StudioCodeRequest { Code = " stayfit " };
        var joinRequest = new JoinStudioRequest
        {
            Code = "stayfit",
            FirstName = "Ana",
            LastName = "Horvat"
        };

        Assert.Same(studios.GetResult, Assert.IsType<OkObjectResult>(
            (await controller.Get()).Result).Value);
        Assert.Same(lookup, Assert.IsType<OkObjectResult>(
            (await controller.Lookup(lookupRequest)).Result).Value);
        Assert.Same(studio, Assert.IsType<OkObjectResult>(
            (await controller.Join(joinRequest)).Result).Value);
        Assert.Same(session, Assert.IsType<OkObjectResult>(
            (await controller.Select(7)).Result).Value);
        Assert.Equal(" stayfit ", studios.LookupCode);
        Assert.Same(joinRequest, studios.JoinRequest);
        Assert.Equal((42, 7), auth.SelectArguments);
    }

    [Fact]
    public async Task FailuresAreMappedForLookupJoinAndSelect()
    {
        var studios = new FakeAccountStudiosService
        {
            LookupResult = ServiceResult<StudioLookupResponse>.NotFound("missing", "detail"),
            JoinResult = ServiceResult<AccountStudioResponse>.Conflict("conflict", "detail")
        };
        var auth = new FakeAuthService
        {
            SelectResult = ServiceResult<LoginResponse>.Forbidden("denied", "detail")
        };
        var controller = new AccountStudiosController(
            studios, auth, new FakeCurrentUserContext(42));

        SchedulingControllerTestAssertions.Problem(
            (await controller.Lookup(new StudioCodeRequest())).Result, 404);
        SchedulingControllerTestAssertions.Problem(
            (await controller.Join(new JoinStudioRequest())).Result, 409);
        SchedulingControllerTestAssertions.Problem(
            (await controller.Select(7)).Result, 403);
    }

    [Fact]
    public void AuthorizationAndRateLimitingContractIsExplicit()
    {
        var authorization = typeof(AccountStudiosController)
            .GetCustomAttribute<AuthorizeAttribute>();
        Assert.Equal("AccountAccess", authorization?.Policy);

        AssertRateLimited(nameof(AccountStudiosController.Lookup));
        AssertRateLimited(nameof(AccountStudiosController.Join));
        Assert.Null(typeof(AccountStudiosController).GetMethod(nameof(AccountStudiosController.Get))!
            .GetCustomAttribute<EnableRateLimitingAttribute>());
        Assert.Null(typeof(AccountStudiosController).GetMethod(nameof(AccountStudiosController.Select))!
            .GetCustomAttribute<EnableRateLimitingAttribute>());
    }

    private static void AssertRateLimited(string methodName)
    {
        var attribute = typeof(AccountStudiosController).GetMethod(methodName)!
            .GetCustomAttribute<EnableRateLimitingAttribute>();
        Assert.Equal("auth", attribute?.PolicyName);
    }

    private static AccountStudioResponse StudioResponse() =>
        new(7, "Stay Fit", 11, null, [AuthRoles.Member]);

    private static LoginResponse LoginResponse() => new(
        "studio-token",
        new DateTime(2030, 1, 1, 12, 0, 0, DateTimeKind.Utc),
        new AuthenticatedUserResponse(42, 7, 11, null, "ana@example.com", [AuthRoles.Member]));

    private sealed class FakeAccountStudiosService : IAccountStudiosService
    {
        public IReadOnlyCollection<AccountStudioResponse> GetResult { get; init; } = [];
        public ServiceResult<StudioLookupResponse> LookupResult { get; init; } = null!;
        public ServiceResult<AccountStudioResponse> JoinResult { get; init; } = null!;
        public string? LookupCode { get; private set; }
        public JoinStudioRequest? JoinRequest { get; private set; }

        public Task<IReadOnlyCollection<AccountStudioResponse>> GetAsync() =>
            Task.FromResult(GetResult);

        public Task<ServiceResult<StudioLookupResponse>> LookupAsync(string code)
        {
            LookupCode = code;
            return Task.FromResult(LookupResult);
        }

        public Task<ServiceResult<AccountStudioResponse>> JoinAsync(JoinStudioRequest request)
        {
            JoinRequest = request;
            return Task.FromResult(JoinResult);
        }
    }

    private sealed class FakeAuthService : IAuthService
    {
        public ServiceResult<LoginResponse> SelectResult { get; init; } = null!;
        public (long UserId, long StudioId)? SelectArguments { get; private set; }

        public Task<ServiceResult<AccountSessionResponse>> LoginAsync(LoginRequest request) =>
            throw new NotSupportedException();

        public Task<ServiceResult<AccountSessionResponse>> RegisterAsync(RegisterRequest request) =>
            throw new NotSupportedException();

        public Task<ServiceResult<LoginResponse>> CreateStudioSessionAsync(long userId, long studioId)
        {
            SelectArguments = (userId, studioId);
            return Task.FromResult(SelectResult);
        }
    }

    private sealed class FakeCurrentUserContext(long userId) : ICurrentUserContext
    {
        public long UserId => userId;
        public string Email => "ana@example.com";
        public long StudioId => throw new InvalidOperationException();
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>();
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => false;
    }
}
