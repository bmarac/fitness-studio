using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Route("api/class-sessions")]
public class ClassSessionsController : ControllerBase
{
    private readonly IClassSessionsService _classSessionsService;

    public ClassSessionsController(IClassSessionsService classSessionsService)
    {
        _classSessionsService = classSessionsService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ClassSessionResponse>>> GetClassSessions()
    {
        return Ok(await _classSessionsService.GetClassSessionsAsync());
    }

    [Authorize(Roles = AuthRoles.Trainer)]
    [HttpGet("mine")]
    public async Task<ActionResult<List<ClassSessionResponse>>> GetMyClassSessions()
    {
        return Ok(await _classSessionsService.GetMyClassSessionsAsync());
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ClassSessionResponse>> GetClassSession(long id)
    {
        var result = await _classSessionsService.GetClassSessionAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpPost]
    public async Task<ActionResult<ClassSessionResponse>> CreateClassSession(CreateClassSessionRequest request)
    {
        var result = await _classSessionsService.CreateClassSessionAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetClassSession), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateClassSession(long id, UpdateClassSessionRequest request)
    {
        var result = await _classSessionsService.UpdateClassSessionAsync(id, request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteClassSession(long id)
    {
        var result = await _classSessionsService.DeleteClassSessionAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Staff)]
    [HttpPatch("{id:long}/cancel")]
    public async Task<IActionResult> CancelClassSession(long id)
    {
        var result = await _classSessionsService.CancelClassSessionAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
