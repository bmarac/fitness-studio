using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize(Roles = AuthRoles.Admin)]
[Route("api/studio-settings/configuration")]
public class StudioConfigurationController : ControllerBase
{
    private readonly IStudioConfigurationService _service;

    public StudioConfigurationController(IStudioConfigurationService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<StudioConfigurationResponse>> Get()
        => Ok(await _service.GetAsync());

    [HttpPut]
    public async Task<ActionResult<StudioConfigurationResponse>> Update(
        UpdateStudioConfigurationRequest request)
    {
        var result = await _service.UpdateAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }
}
