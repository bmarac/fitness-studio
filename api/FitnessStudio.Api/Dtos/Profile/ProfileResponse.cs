using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Dtos.Trainers;

namespace FitnessStudio.Api.Dtos.Profile;

public record ProfileResponse(
    ProfileUserResponse User,
    StudioResponse Studio,
    MemberResponse? Member,
    TrainerResponse? Trainer,
    ProfileMembershipResponse? Membership,
    ProfileUsageResponse? Usage,
    IReadOnlyCollection<MemberFixedScheduleResponse> FixedSchedules);

public record ProfileUserResponse(
    long Id,
    string Email,
    IReadOnlyCollection<string> Roles);

public record ProfileMembershipResponse(
    long Id,
    long PlanId,
    string PlanName,
    string? PlanDescription,
    DateOnly StartsOn,
    DateOnly EndsOn,
    string Status,
    int? SessionLimit,
    string? SessionLimitPeriod,
    decimal PriceAmount,
    string Currency);

public record ProfileUsageResponse(
    DateOnly PeriodStartsOn,
    DateOnly PeriodEndsOn,
    int Used,
    int Allowed,
    string Period);
