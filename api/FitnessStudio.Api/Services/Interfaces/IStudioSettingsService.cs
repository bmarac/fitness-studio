using FitnessStudio.Api.Dtos.StudioSettings;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IStudioSettingsService
{
    Task<List<StudioSettingResponse>> GetSettingsAsync();
    Task<ServiceResult<StudioSettingResponse>> GetSettingAsync(string setting);
    Task<ServiceResult<StudioSettingResponse>> UpsertSettingAsync(string setting, UpsertStudioSettingRequest request);
    Task<ServiceResult> DeleteSettingAsync(string setting);
}
