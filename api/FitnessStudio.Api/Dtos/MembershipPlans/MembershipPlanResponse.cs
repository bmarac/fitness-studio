namespace FitnessStudio.Api.Dtos.MembershipPlans;

public record MembershipPlanResponse(
    long Id,
    string Name,
    string? Description,
    int DurationDays,
    int? SessionLimit,
    string? SessionLimitPeriod,
    decimal PriceAmount,
    string Currency,
    string Status);
