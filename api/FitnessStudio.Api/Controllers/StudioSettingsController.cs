using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/studio-settings")]
public class StudioSettingsController : ControllerBase
{
    private readonly IStudioSettingsService _service;

    public StudioSettingsController(IStudioSettingsService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<List<StudioSettingResponse>>> GetSettings()
        => Ok(await _service.GetSettingsAsync());

    [HttpGet("{setting}")]
    public async Task<ActionResult<StudioSettingResponse>> GetSetting(string setting)
    {
        var result = await _service.GetSettingAsync(setting);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{setting}")]
    public async Task<ActionResult<StudioSettingResponse>> UpsertSetting(
        string setting,
        UpsertStudioSettingRequest request)
    {
        var result = await _service.UpsertSettingAsync(setting, request);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{setting}")]
    public async Task<IActionResult> DeleteSetting(string setting)
    {
        var result = await _service.DeleteSettingAsync(setting);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }
}
