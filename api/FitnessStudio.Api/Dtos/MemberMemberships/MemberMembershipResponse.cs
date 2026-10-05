namespace FitnessStudio.Api.Dtos.MemberMemberships;

public record MemberMembershipResponse(
    long Id,
    long MemberId,
    string MemberName,
    long MembershipPlanId,
    string MembershipPlanName,
    DateOnly StartsOn,
    DateOnly EndsOn,
    string Status);
