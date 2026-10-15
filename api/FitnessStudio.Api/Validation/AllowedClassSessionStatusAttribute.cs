using FitnessStudio.Api.Domain.ClassSessions;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedClassSessionStatusAttribute : AllowedStringValuesAttribute
{
    public AllowedClassSessionStatusAttribute()
        : base("Status", ClassSessionStatuses.All, ClassSessionStatuses.IsValid)
    {
    }
}
