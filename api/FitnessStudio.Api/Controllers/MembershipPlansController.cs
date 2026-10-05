using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/membership-plans")]
public class MembershipPlansController : ControllerBase
{
    private readonly IMembershipPlansService _service;

    public MembershipPlansController(IMembershipPlansService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<List<MembershipPlanResponse>>> GetPlans()
        => Ok(await _service.GetPlansAsync());

    [HttpGet("{id:long}")]
    public async Task<ActionResult<MembershipPlanResponse>> GetPlan(long id)
    {
        var result = await _service.GetPlanAsync(id);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPost]
    public async Task<ActionResult<MembershipPlanResponse>> CreatePlan(CreateMembershipPlanRequest request)
    {
        var result = await _service.CreatePlanAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetPlan), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdatePlan(long id, UpdateMembershipPlanRequest request)
    {
        var result = await _service.UpdatePlanAsync(id, request);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeletePlan(long id)
    {
        var result = await _service.DeletePlanAsync(id);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }
}
