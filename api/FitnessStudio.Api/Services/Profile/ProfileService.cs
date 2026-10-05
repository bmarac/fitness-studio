using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Dtos.Profile;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Services.Interfaces;

namespace FitnessStudio.Api.Services.Profile;

public class ProfileService : IProfileService
{
    private readonly IBookingsService _bookingsService;
    private readonly ICurrentUserContext _currentUser;
    private readonly IMemberFixedSchedulesService _fixedSchedulesService;
    private readonly IMemberMembershipsService _membershipsService;
    private readonly IMembersService _membersService;
    private readonly IMembershipPlansService _plansService;
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
        IBookingsService bookingsService)
    {
        _currentUser = currentUser;
        _studiosService = studiosService;
        _membersService = membersService;
        _trainersService = trainersService;
        _membershipsService = membershipsService;
        _plansService = plansService;
        _fixedSchedulesService = fixedSchedulesService;
        _bookingsService = bookingsService;
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
                var today = GetStudioToday(studioResult.Value!.Timezone);
                var period = GetUsagePeriod(currentMembership, plan.SessionLimitPeriod, today);
                var used = await _bookingsService.GetCurrentMemberUsageAsync(period.StartsOn, period.EndsOn);
                usage = new ProfileUsageResponse(
                    period.StartsOn,
                    period.EndsOn,
                    used,
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
            membership.Status,
            plan.SessionLimit,
            plan.SessionLimitPeriod,
            plan.PriceAmount,
            plan.Currency);
    }

    private static (DateOnly StartsOn, DateOnly EndsOn) GetUsagePeriod(
        MemberMembershipResponse membership,
        string period,
        DateOnly today)
    {
        var calculated = period switch
        {
            "week" => GetWeek(today),
            "month" => GetMonth(today),
            "membership" => (membership.StartsOn, membership.EndsOn),
            _ => throw new InvalidOperationException($"Unsupported membership limit period '{period}'.")
        };

        return (
            calculated.Item1 < membership.StartsOn ? membership.StartsOn : calculated.Item1,
            calculated.Item2 > membership.EndsOn ? membership.EndsOn : calculated.Item2);
    }

    private static (DateOnly, DateOnly) GetWeek(DateOnly today)
    {
        var daysSinceMonday = ((int)today.DayOfWeek + 6) % 7;
        var startsOn = today.AddDays(-daysSinceMonday);
        return (startsOn, startsOn.AddDays(6));
    }

    private static (DateOnly, DateOnly) GetMonth(DateOnly today)
    {
        var startsOn = new DateOnly(today.Year, today.Month, 1);
        return (startsOn, startsOn.AddMonths(1).AddDays(-1));
    }

    private static DateOnly GetStudioToday(string timezoneId)
    {
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
    }

    private static ServiceResult<ProfileResponse> ToProfileFailure<TSource>(ServiceResult<TSource> source)
    {
        return new ServiceResult<ProfileResponse>(source.Status, default, source.Error);
    }
}
