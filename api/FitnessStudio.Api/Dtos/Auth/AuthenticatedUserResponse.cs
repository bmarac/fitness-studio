namespace FitnessStudio.Api.Dtos.Auth;

public record AuthenticatedUserResponse(
    long Id,
    long StudioId,
    long? MemberId,
    long? TrainerId,
    string Email,
    IReadOnlyCollection<string> Roles);
