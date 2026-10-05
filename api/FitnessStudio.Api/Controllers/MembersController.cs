using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class MembersController : ControllerBase
{
    private readonly IMembersService _membersService;

    public MembersController(IMembersService membersService)
    {
        _membersService = membersService;
    }

    [Authorize(Roles = AuthRoles.Staff)]
    [HttpGet]
    public async Task<ActionResult<List<MemberResponse>>> GetMembers()
    {
        return Ok(await _membersService.GetMembersAsync());
    }

    [Authorize(Roles = AuthRoles.Staff)]
    [HttpGet("{id:long}")]
    public async Task<ActionResult<MemberResponse>> GetMember(long id)
    {
        var result = await _membersService.GetMemberAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPost]
    public async Task<ActionResult<MemberResponse>> CreateMember(CreateMemberRequest request)
    {
        var result = await _membersService.CreateMemberAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetMember), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateMember(long id, UpdateMemberRequest request)
    {
        var result = await _membersService.UpdateMemberAsync(id, request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteMember(long id)
    {
        var result = await _membersService.DeleteMemberAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
