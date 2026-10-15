using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Validation;

public abstract class AllowedStringValuesAttribute : ValidationAttribute
{
    private readonly string _valueName;
    private readonly IReadOnlyCollection<string> _allowedValues;
    private readonly Func<string, bool> _isAllowed;

    protected AllowedStringValuesAttribute(
        string valueName,
        IReadOnlyCollection<string> allowedValues,
        Func<string, bool> isAllowed)
    {
        _valueName = valueName;
        _allowedValues = allowedValues;
        _isAllowed = isAllowed;
    }

    protected override ValidationResult? IsValid(
        object? value,
        ValidationContext validationContext)
    {
        if (value is null)
        {
            return ValidationResult.Success;
        }

        if (value is string text && _isAllowed(text))
        {
            return ValidationResult.Success;
        }

        return new ValidationResult(
            $"{_valueName} must be one of: {string.Join(", ", _allowedValues)}.");
    }
}
