using FitnessStudio.Api.Dtos.Studios;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IStudiosService
{
    Task<ServiceResult<StudioResponse>> GetCurrentStudioAsync();

    Task<ServiceResult> UpdateCurrentStudioAsync(UpdateStudioRequest request);
}
