namespace FitnessStudio.Api.Domain.Members;

public static class MemberStatuses
{
    public const string Active = "active";
    public const string Inactive = "inactive";
    public const string Paused = "paused";
    public const string Blocked = "blocked";

    public static readonly string[] All =
    [
        Active,
        Inactive,
        Paused,
        Blocked
    ];

    public static bool IsValid(string status)
    {
        return All.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}
