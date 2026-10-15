using FitnessStudio.Api.Domain.ClassTypes;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedClassTypeDifficultyLevelAttribute : AllowedStringValuesAttribute
{
    public AllowedClassTypeDifficultyLevelAttribute()
        : base(
            "Difficulty level",
            ClassTypeDifficultyLevels.All,
            ClassTypeDifficultyLevels.IsValid)
    {
    }
}
