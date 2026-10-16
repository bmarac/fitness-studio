namespace FitnessStudio.Api.Dtos.Auth;

public record AccountSessionResponse(
    string AccessToken,
    DateTime ExpiresAt,
    string? RefreshToken,
    DateTime? RefreshTokenExpiresAt,
    AccountUserResponse User,
    IReadOnlyCollection<AccountStudioResponse> Studios);

public record AccountUserResponse(long Id, string Email);

public record AccountStudioResponse(
    long StudioId,
    string StudioName,
    long? MemberId,
    long? TrainerId,
    IReadOnlyCollection<string> Roles);
