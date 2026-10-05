using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MeasurementParameters;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/measurement-parameters")]
public class MeasurementParametersController : ControllerBase
{
    private readonly IMeasurementParametersService _service;

    public MeasurementParametersController(IMeasurementParametersService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<List<MeasurementParameterResponse>>> GetParameters()
        => Ok(await _service.GetParametersAsync());

    [HttpGet("{id:long}")]
    public async Task<ActionResult<MeasurementParameterResponse>> GetParameter(long id)
    {
        var result = await _service.GetParameterAsync(id);
        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPost]
    public async Task<ActionResult<MeasurementParameterResponse>> CreateParameter(
        CreateMeasurementParameterRequest request)
    {
        var result = await _service.CreateParameterAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetParameter), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateParameter(
        long id,
        UpdateMeasurementParameterRequest request)
    {
        var result = await _service.UpdateParameterAsync(id, request);
        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteParameter(long id)
    {
        var result = await _service.DeleteParameterAsync(id);
        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
