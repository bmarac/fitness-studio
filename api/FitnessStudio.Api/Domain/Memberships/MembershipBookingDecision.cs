namespace FitnessStudio.Api.Domain.Memberships;

public enum MembershipBookingDecisionStatus
{
    Allowed,
    MissingMembership,
    LimitReached
}

public sealed record MembershipBookingDecision(
    MembershipBookingDecisionStatus Status,
    DateOnly? PeriodStartsOn = null,
    DateOnly? PeriodEndsOn = null,
    int Used = 0,
    int? Allowed = null)
{
    public bool IsAllowed => Status == MembershipBookingDecisionStatus.Allowed;
}
