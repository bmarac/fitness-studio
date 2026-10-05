namespace FitnessStudio.Api.Dtos.Auth;

public record LoginResponse(
    string AccessToken,
    DateTime ExpiresAt,
    AuthenticatedUserResponse User);
