using FitnessStudio.Api.Dtos.Trainers;

namespace FitnessStudio.Api.Services.Interfaces;

public interface ITrainersService
{
    Task<List<TrainerResponse>> GetTrainersAsync();

    Task<ServiceResult<TrainerResponse>> GetTrainerAsync(long id);

    Task<ServiceResult<TrainerResponse>> CreateTrainerAsync(CreateTrainerRequest request);

    Task<ServiceResult> UpdateTrainerAsync(long id, UpdateTrainerRequest request);

    Task<ServiceResult> DeleteTrainerAsync(long id);
}
