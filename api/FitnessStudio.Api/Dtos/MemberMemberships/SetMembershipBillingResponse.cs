namespace FitnessStudio.Api.Dtos.MemberMemberships;

public record SetMembershipBillingResponse(
    MemberMembershipResponse Membership,
    int CreatedObligations,
    DateOnly? NextBillingOn);
