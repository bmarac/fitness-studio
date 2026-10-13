using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [AllowAnonymous]
    [HttpPost("login")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AccountSessionResponse>> Login(LoginRequest request)
    {
        var result = await _authService.LoginAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [AllowAnonymous]
    [HttpPost("register")]
    [EnableRateLimiting("auth")]
    public async Task<ActionResult<AccountSessionResponse>> Register(RegisterRequest request)
    {
        var result = await _authService.RegisterAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? Created("/api/account/studios", result.Value)
            : this.ToActionResult(result);
    }
}
