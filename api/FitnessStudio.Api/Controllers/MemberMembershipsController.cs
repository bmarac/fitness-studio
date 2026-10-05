using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/member-memberships")]
public class MemberMembershipsController : ControllerBase
{
    private readonly IMemberMembershipsService _service;

    public MemberMembershipsController(IMemberMembershipsService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<List<MemberMembershipResponse>>> GetMemberships()
        => Ok(await _service.GetMembershipsAsync());

    [HttpGet("{id:long}")]
    public async Task<ActionResult<MemberMembershipResponse>> GetMembership(long id)
    {
        var result = await _service.GetMembershipAsync(id);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPost]
    public async Task<ActionResult<MemberMembershipResponse>> CreateMembership(
        CreateMemberMembershipRequest request)
    {
        var result = await _service.CreateMembershipAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetMembership), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateMembership(long id, UpdateMemberMembershipRequest request)
    {
        var result = await _service.UpdateMembershipAsync(id, request);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteMembership(long id)
    {
        var result = await _service.DeleteMembershipAsync(id);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }
}
