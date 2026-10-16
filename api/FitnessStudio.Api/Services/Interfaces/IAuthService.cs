using FitnessStudio.Api.Dtos.Auth;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IAuthService
{
    Task<ServiceResult<AccountSessionResponse>> LoginAsync(LoginRequest request);
    Task<ServiceResult<AccountSessionResponse>> RegisterAsync(RegisterRequest request);
    Task<ServiceResult<AccountSessionResponse>> RefreshAsync(string refreshToken);
    Task LogoutAsync(string refreshToken);
    Task<ServiceResult<LoginResponse>> CreateStudioSessionAsync(long userId, long studioId);
}
