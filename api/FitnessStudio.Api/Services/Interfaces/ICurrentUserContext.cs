namespace FitnessStudio.Api.Services.Interfaces;

public interface ICurrentUserContext
{
    long UserId { get; }

    string Email { get; }

    long StudioId { get; }

    long? MemberId { get; }

    long? TrainerId { get; }

    IReadOnlySet<string> Roles { get; }

    bool IsMemberOnly { get; }

    bool IsInRole(string role);
}
