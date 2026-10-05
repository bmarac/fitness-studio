using FitnessStudio.Api.Dtos.ClassTypes;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Route("api/class-types")]
public class ClassTypesController : ControllerBase
{
    private readonly IClassTypesService _classTypesService;

    public ClassTypesController(IClassTypesService classTypesService)
    {
        _classTypesService = classTypesService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ClassTypeResponse>>> GetClassTypes()
    {
        return Ok(await _classTypesService.GetClassTypesAsync());
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<ClassTypeResponse>> GetClassType(long id)
    {
        var result = await _classTypesService.GetClassTypeAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpPost]
    public async Task<ActionResult<ClassTypeResponse>> CreateClassType(CreateClassTypeRequest request)
    {
        var result = await _classTypesService.CreateClassTypeAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetClassType), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateClassType(long id, UpdateClassTypeRequest request)
    {
        var result = await _classTypesService.UpdateClassTypeAsync(id, request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteClassType(long id)
    {
        var result = await _classTypesService.DeleteClassTypeAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
