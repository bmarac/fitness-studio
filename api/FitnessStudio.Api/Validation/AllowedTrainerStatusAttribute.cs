using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Domain.Trainers;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedTrainerStatusAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is null)
        {
            return ValidationResult.Success;
        }

        if (value is string status && TrainerStatuses.IsValid(status))
        {
            return ValidationResult.Success;
        }

        return new ValidationResult($"Status must be one of: {string.Join(", ", TrainerStatuses.All)}.");
    }
}
