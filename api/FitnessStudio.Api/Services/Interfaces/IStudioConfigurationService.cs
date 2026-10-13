using FitnessStudio.Api.Dtos.StudioSettings;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IStudioConfigurationService
{
    Task<StudioConfigurationResponse> GetAsync();

    Task<ServiceResult<StudioConfigurationResponse>> UpdateAsync(
        UpdateStudioConfigurationRequest request);
}
