namespace FitnessStudio.Api.Domain.ClassTypes;

public static class ClassTypeDifficultyLevels
{
    public const string Beginner = "beginner";
    public const string Intermediate = "intermediate";
    public const string Advanced = "advanced";
    public const string AllLevels = "all_levels";

    public static readonly string[] All =
    [
        Beginner,
        Intermediate,
        Advanced,
        AllLevels
    ];

    public static bool IsValid(string difficultyLevel)
    {
        return All.Contains(difficultyLevel, StringComparer.OrdinalIgnoreCase);
    }
}
