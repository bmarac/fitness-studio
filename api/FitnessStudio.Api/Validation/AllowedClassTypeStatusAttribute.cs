using FitnessStudio.Api.Domain.ClassTypes;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedClassTypeStatusAttribute : AllowedStringValuesAttribute
{
    public AllowedClassTypeStatusAttribute()
        : base("Status", ClassTypeStatuses.All, ClassTypeStatuses.IsValid)
    {
    }
}
