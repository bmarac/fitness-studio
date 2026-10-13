using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize(Policy = "AccountAccess")]
[Route("api/account/studios")]
public class AccountStudiosController : ControllerBase
{
    private readonly IAccountStudiosService _studios;
    private readonly IAuthService _auth;
    private readonly ICurrentUserContext _currentUser;

    public AccountStudiosController(
        IAccountStudiosService studios,
        IAuthService auth,
        ICurrentUserContext currentUser)
    {
        _studios = studios;
        _auth = auth;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<AccountStudioResponse>>> Get() =>
        Ok(await _studios.GetAsync());

    [HttpPost("lookup")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<StudioLookupResponse>> Lookup(StudioCodeRequest request)
    {
        var result = await _studios.LookupAsync(request.Code);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [HttpPost("join")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AccountStudioResponse>> Join(JoinStudioRequest request)
    {
        var result = await _studios.JoinAsync(request);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [HttpPost("{studioId:long}/select")]
    public async Task<ActionResult<LoginResponse>> Select(long studioId)
    {
        var result = await _auth.CreateStudioSessionAsync(_currentUser.UserId, studioId);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }
}
