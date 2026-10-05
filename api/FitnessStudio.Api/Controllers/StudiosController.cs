using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/studios")]
public class StudiosController : ControllerBase
{
    private readonly IStudiosService _studiosService;

    public StudiosController(IStudiosService studiosService)
    {
        _studiosService = studiosService;
    }

    [HttpGet("current")]
    public async Task<ActionResult<StudioResponse>> GetCurrentStudio()
    {
        var result = await _studiosService.GetCurrentStudioAsync();

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("current")]
    public async Task<IActionResult> UpdateCurrentStudio(UpdateStudioRequest request)
    {
        var result = await _studiosService.UpdateCurrentStudioAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
