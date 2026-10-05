namespace FitnessStudio.Api.Domain.ClassTypes;

public static class ClassTypeStatuses
{
    public const string Active = "active";
    public const string Inactive = "inactive";

    public static readonly string[] All =
    [
        Active,
        Inactive
    ];

    public static bool IsValid(string status)
    {
        return All.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}
