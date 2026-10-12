using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Dtos.Profile;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Services.Interfaces;

namespace FitnessStudio.Api.Services.Profile;

public class ProfileService : IProfileService
{
    private readonly ICurrentUserContext _currentUser;
    private readonly IMemberFixedSchedulesService _fixedSchedulesService;
    private readonly IMemberMembershipsService _membershipsService;
    private readonly IMembersService _membersService;
    private readonly IMembershipPlansService _plansService;
    private readonly IMembershipBookingPolicy _membershipBookingPolicy;
    private readonly IStudiosService _studiosService;
    private readonly ITrainersService _trainersService;

    public ProfileService(
        ICurrentUserContext currentUser,
        IStudiosService studiosService,
        IMembersService membersService,
        ITrainersService trainersService,
        IMemberMembershipsService membershipsService,
        IMembershipPlansService plansService,
        IMemberFixedSchedulesService fixedSchedulesService,
        IMembershipBookingPolicy membershipBookingPolicy)
    {
        _currentUser = currentUser;
        _studiosService = studiosService;
        _membersService = membersService;
        _trainersService = trainersService;
        _membershipsService = membershipsService;
        _plansService = plansService;
        _fixedSchedulesService = fixedSchedulesService;
        _membershipBookingPolicy = membershipBookingPolicy;
    }

    public async Task<ServiceResult<ProfileResponse>> GetProfileAsync()
    {
        var studioResult = await _studiosService.GetCurrentStudioAsync();
        if (studioResult.Status != ServiceResultStatus.Success)
        {
            return ToProfileFailure(studioResult);
        }

        MemberResponse? member = null;
        if (_currentUser.MemberId.HasValue)
        {
            var memberResult = await _membersService.GetMemberAsync(_currentUser.MemberId.Value);
            if (memberResult.Status != ServiceResultStatus.Success)
            {
                return ToProfileFailure(memberResult);
            }

            member = memberResult.Value;
        }

        TrainerResponse? trainer = null;
        if (_currentUser.TrainerId.HasValue)
        {
            var trainerResult = await _trainersService.GetTrainerAsync(_currentUser.TrainerId.Value);
            if (trainerResult.Status != ServiceResultStatus.Success)
            {
                return ToProfileFailure(trainerResult);
            }

            trainer = trainerResult.Value;
        }

        ProfileMembershipResponse? membership = null;
        ProfileUsageResponse? usage = null;
        var currentMembership = await _membershipsService.GetCurrentMemberMembershipAsync();

        if (currentMembership is not null)
        {
            var planResult = await _plansService.GetPlanAsync(currentMembership.MembershipPlanId);
            if (planResult.Status != ServiceResultStatus.Success)
            {
                return ToProfileFailure(planResult);
            }

            var plan = planResult.Value!;
            membership = ToMembership(currentMembership, plan);

            if (plan.SessionLimit.HasValue && plan.SessionLimitPeriod is not null)
            {
                var entitlement = await _membershipBookingPolicy.EvaluateAsync(
                    currentMembership.MemberId,
                    DateTime.UtcNow);
                usage = new ProfileUsageResponse(
                    entitlement.PeriodStartsOn!.Value,
                    entitlement.PeriodEndsOn!.Value,
                    entitlement.Used,
                    plan.SessionLimit.Value,
                    plan.SessionLimitPeriod);
            }
        }

        var fixedSchedules = await _fixedSchedulesService.GetCurrentMemberSchedulesAsync();

        return ServiceResult<ProfileResponse>.Success(new ProfileResponse(
            new ProfileUserResponse(
                _currentUser.UserId,
                _currentUser.Email,
                _currentUser.Roles.OrderBy(role => role).ToArray()),
            studioResult.Value!,
            member,
            trainer,
            membership,
            usage,
            fixedSchedules));
    }

    private static ProfileMembershipResponse ToMembership(
        MemberMembershipResponse membership,
        MembershipPlanResponse plan)
    {
        return new ProfileMembershipResponse(
            membership.Id,
            plan.Id,
            plan.Name,
            plan.Description,
            membership.StartsOn,
            membership.EndsOn,
            membership.IsActive,
            plan.SessionLimit,
            plan.SessionLimitPeriod,
            plan.PriceAmount,
            plan.Currency);
    }

    private static ServiceResult<ProfileResponse> ToProfileFailure<TSource>(ServiceResult<TSource> source)
    {
        return new ServiceResult<ProfileResponse>(source.Status, default, source.Error);
    }
}
