using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.RecurringClassSchedules;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/recurring-class-schedules")]
public class RecurringClassSchedulesController : ControllerBase
{
    private readonly IRecurringClassSchedulesService _service;

    public RecurringClassSchedulesController(IRecurringClassSchedulesService service) => _service = service;

    [HttpGet]
    public async Task<ActionResult<List<RecurringClassScheduleResponse>>> GetSchedules()
        => Ok(await _service.GetSchedulesAsync());

    [HttpGet("{id:long}")]
    public async Task<ActionResult<RecurringClassScheduleResponse>> GetSchedule(long id)
    {
        var result = await _service.GetScheduleAsync(id);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPost]
    public async Task<ActionResult<RecurringClassScheduleResponse>> CreateSchedule(
        CreateRecurringClassScheduleRequest request)
    {
        var result = await _service.CreateScheduleAsync(request);
        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetSchedule), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateSchedule(long id, UpdateRecurringClassScheduleRequest request)
    {
        var result = await _service.UpdateScheduleAsync(id, request);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }

    [Authorize(Roles = AuthRoles.Admin)]
    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteSchedule(long id)
    {
        var result = await _service.DeleteScheduleAsync(id);
        return result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    }
}
