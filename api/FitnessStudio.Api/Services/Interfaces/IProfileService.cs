using FitnessStudio.Api.Dtos.Profile;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IProfileService
{
    Task<ServiceResult<ProfileResponse>> GetProfileAsync();
}
