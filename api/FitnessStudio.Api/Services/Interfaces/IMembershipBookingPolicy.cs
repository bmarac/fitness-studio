using FitnessStudio.Api.Domain.Memberships;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMembershipBookingPolicy
{
    Task AcquireMemberLockAsync(long memberId);

    Task<MembershipBookingDecision> EvaluateAsync(
        long memberId,
        DateTime classSessionStartsAt,
        long? ignoredBookingId = null);
}
