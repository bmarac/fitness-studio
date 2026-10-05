using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Domain.ClassTypes;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedClassTypeStatusAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is null)
        {
            return ValidationResult.Success;
        }

        if (value is string status && ClassTypeStatuses.IsValid(status))
        {
            return ValidationResult.Success;
        }

        return new ValidationResult($"Status must be one of: {string.Join(", ", ClassTypeStatuses.All)}.");
    }
}
