using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Domain.Bookings;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedBookingStatusAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is null)
        {
            return ValidationResult.Success;
        }

        if (value is string status && BookingStatuses.IsValid(status))
        {
            return ValidationResult.Success;
        }

        return new ValidationResult($"Status must be one of: {string.Join(", ", BookingStatuses.All)}.");
    }
}
