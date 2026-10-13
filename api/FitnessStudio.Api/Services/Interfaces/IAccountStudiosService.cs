using FitnessStudio.Api.Dtos.Auth;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IAccountStudiosService
{
    Task<IReadOnlyCollection<AccountStudioResponse>> GetAsync();
    Task<ServiceResult<StudioLookupResponse>> LookupAsync(string code);
    Task<ServiceResult<AccountStudioResponse>> JoinAsync(JoinStudioRequest request);
}
