using FitnessStudio.Api.Domain.Trainers;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedTrainerStatusAttribute : AllowedStringValuesAttribute
{
    public AllowedTrainerStatusAttribute()
        : base("Status", TrainerStatuses.All, TrainerStatuses.IsValid)
    {
    }
}
