using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMeasurements;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/members/{memberId:long}/measurements")]
public class MemberMeasurementsController : ControllerBase
{
    private readonly IMemberMeasurementsService _service;

    public MemberMeasurementsController(IMemberMeasurementsService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<List<MemberMeasurementResponse>>> GetMeasurements(long memberId)
    {
        var result = await _service.GetMeasurementsAsync(memberId);
        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpGet("latest")]
    public async Task<ActionResult<MemberLatestMeasurementsResponse>> GetLatestMeasurements(long memberId)
    {
        var result = await _service.GetLatestMeasurementsAsync(memberId);
        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Staff)]
    [HttpPost]
    public async Task<ActionResult<MemberMeasurementResponse>> CreateMeasurement(
        long memberId,
        CreateMemberMeasurementRequest request)
    {
        var result = await _service.CreateMeasurementAsync(memberId, request);
        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetMeasurements), new { memberId }, result.Value)
            : this.ToActionResult(result);
    }
}
