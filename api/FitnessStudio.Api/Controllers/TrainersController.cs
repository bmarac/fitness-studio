using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TrainersController : ControllerBase
{
    private readonly ITrainersService _trainersService;

    public TrainersController(ITrainersService trainersService)
    {
        _trainersService = trainersService;
    }

    [HttpGet]
    public async Task<ActionResult<List<TrainerResponse>>> GetTrainers()
    {
        return Ok(await _trainersService.GetTrainersAsync());
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<TrainerResponse>> GetTrainer(long id)
    {
        var result = await _trainersService.GetTrainerAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpPost]
    public async Task<ActionResult<TrainerResponse>> CreateTrainer(CreateTrainerRequest request)
    {
        var result = await _trainersService.CreateTrainerAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetTrainer), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> UpdateTrainer(long id, UpdateTrainerRequest request)
    {
        var result = await _trainersService.UpdateTrainerAsync(id, request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> DeleteTrainer(long id)
    {
        var result = await _trainersService.DeleteTrainerAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
