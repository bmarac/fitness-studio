using FitnessStudio.Api.Domain.Bookings;

namespace FitnessStudio.Api.Validation;

[AttributeUsage(AttributeTargets.Property | AttributeTargets.Parameter)]
public sealed class AllowedBookingStatusAttribute : AllowedStringValuesAttribute
{
    public AllowedBookingStatusAttribute()
        : base(
            "Status",
            BookingStatuses.ManuallyAssignable,
            BookingStatuses.IsManuallyAssignable)
    {
    }
}
