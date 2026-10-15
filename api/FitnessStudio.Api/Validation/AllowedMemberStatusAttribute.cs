using FitnessStudio.Api.Domain.Members;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedMemberStatusAttribute : AllowedStringValuesAttribute
{
    public AllowedMemberStatusAttribute()
        : base("Status", MemberStatuses.All, MemberStatuses.IsValid)
    {
    }
}
