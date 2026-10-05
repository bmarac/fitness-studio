using FitnessStudio.Api.Dtos.Auth;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IAuthService
{
    Task<ServiceResult<LoginResponse>> LoginAsync(LoginRequest request);
}
