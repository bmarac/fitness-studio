using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.MembershipPayments;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MemberMemberships;

public class MemberMembershipsService : IMemberMembershipsService
{
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;
    private readonly IPaymentSettingsService _paymentSettingsService;

    public MemberMembershipsService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser,
        IPaymentSettingsService paymentSettingsService)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
        _paymentSettingsService = paymentSettingsService;
    }

    public async Task<List<MemberMembershipResponse>> GetMembershipsAsync()
    {
        var today = await GetStudioTodayAsync();
        return await Project(QueryMemberships()
                .OrderByDescending(membership => membership.StartsOn), today)
            .ToListAsync();
    }

    public async Task<MemberMembershipResponse?> GetCurrentMemberMembershipAsync()
    {
        if (!_currentUser.MemberId.HasValue)
        {
            return null;
        }

        var today = await GetStudioTodayAsync();

        return await Project(_dbContext.MemberMemberships
                .AsNoTracking()
                .Where(membership =>
                    membership.StudioId == _currentUser.StudioId
                    && membership.MemberId == _currentUser.MemberId.Value
                    && membership.StartsOn <= today
                    && (!membership.EndsOn.HasValue || membership.EndsOn.Value > today))
                .OrderByDescending(membership => membership.StartsOn), today)
            .FirstOrDefaultAsync();
    }

    public async Task<ServiceResult<MemberMembershipResponse>> GetMembershipAsync(long id)
    {
        var today = await GetStudioTodayAsync();
        var membership = await Project(QueryMemberships().Where(item => item.Id == id), today)
            .FirstOrDefaultAsync();

        return membership is null
            ? ServiceResult<MemberMembershipResponse>.NotFound(
                "Member membership not found.",
                "A membership with this id does not exist.")
            : ServiceResult<MemberMembershipResponse>.Success(membership);
    }

    public async Task<ServiceResult<MemberMembershipResponse>> CreateMembershipAsync(
        CreateMemberMembershipRequest request)
    {
        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return new ServiceResult<MemberMembershipResponse>(
                validationResult.Status,
                default,
                validationResult.Error);
        }

        var now = DateTime.UtcNow;
        var membership = new MemberMembership
        {
            StudioId = _currentUser.StudioId,
            MemberId = request.MemberId,
            MembershipPlanId = request.MembershipPlanId,
            StartsOn = request.StartsOn,
            EndsOn = request.EndsOn,
            BillingStartsOn = request.NextBillingOn ?? request.StartsOn,
            NextBillingOn = request.NextBillingOn ?? request.StartsOn,
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.MemberMemberships.Add(membership);
        await _dbContext.SaveChangesAsync();

        return await GetMembershipAsync(membership.Id);
    }

    public async Task<ServiceResult> UpdateMembershipAsync(long id, UpdateMemberMembershipRequest request)
    {
        var membership = await _dbContext.MemberMemberships.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (membership is null)
        {
            return ServiceResult.NotFound(
                "Member membership not found.",
                "A membership with this id does not exist.");
        }

        var validationResult = await ValidateRequestAsync(request, id);
        if (validationResult is not null)
        {
            return validationResult;
        }
        if (membership.BillingStartsOn is { } billingStart
            && (billingStart < request.StartsOn
                || request.EndsOn.HasValue && billingStart >= request.EndsOn.Value))
        {
            return ServiceResult.Conflict(
                "Invalid membership dates.",
                "The membership period must continue to contain the billing start date.");
        }

        membership.MemberId = request.MemberId;
        membership.MembershipPlanId = request.MembershipPlanId;
        membership.StartsOn = request.StartsOn;
        membership.EndsOn = request.EndsOn;
        membership.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteMembershipAsync(long id)
    {
        var membership = await _dbContext.MemberMemberships.FirstOrDefaultAsync(item =>
            item.Id == id && item.StudioId == _currentUser.StudioId);

        if (membership is null)
        {
            return ServiceResult.NotFound(
                "Member membership not found.",
                "A membership with this id does not exist.");
        }

        _dbContext.MemberMemberships.Remove(membership);
        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult<SetMembershipBillingResponse>> SetBillingAsync(long id, SetMembershipBillingRequest request)
    {
        var membership = await _dbContext.MemberMemberships
            .Include(item => item.Member)
            .Include(item => item.MembershipPlan)
            .FirstOrDefaultAsync(item => item.Id == id && item.StudioId == _currentUser.StudioId);
        if (membership is null)
            return ServiceResult<SetMembershipBillingResponse>.NotFound(
                "Member membership not found.", "A membership with this id does not exist.");
        if (membership.BillingStartsOn.HasValue)
            return ServiceResult<SetMembershipBillingResponse>.Conflict(
                "Billing is already enabled.", "Billing has already been enabled for this membership.");
        if (request.FirstBillingOn < membership.StartsOn || membership.EndsOn.HasValue && request.FirstBillingOn >= membership.EndsOn.Value)
            return ServiceResult<SetMembershipBillingResponse>.Conflict(
                "Invalid first billing date.", "The first billing date must be inside the membership period.");

        var settings = await _paymentSettingsService.GetAsync();
        if (!settings.IsComplete)
            return ServiceResult<SetMembershipBillingResponse>.Conflict(
                "Payment settings are incomplete.",
                "Open payment settings and enter the recipient, valid IBAN, reference and description before enabling billing.");

        var today = await GetStudioTodayAsync();
        await using var transaction = await _dbContext.Database.BeginTransactionAsync();
        membership.BillingStartsOn = request.FirstBillingOn;
        membership.NextBillingOn = request.FirstBillingOn;
        membership.UpdatedAt = DateTime.UtcNow;
        var created = await MembershipObligationGenerator.GenerateDueAsync(
            _dbContext, membership, settings, today);
        await _dbContext.SaveChangesAsync();
        await transaction.CommitAsync();

        var response = new MemberMembershipResponse(
            membership.Id,
            membership.MemberId,
            membership.Member.FirstName + " " + membership.Member.LastName,
            membership.MembershipPlanId,
            membership.MembershipPlan.Name,
            membership.StartsOn,
            membership.EndsOn,
            membership.BillingStartsOn,
            membership.NextBillingOn,
            membership.StartsOn <= today
            && (!membership.EndsOn.HasValue || membership.EndsOn.Value > today));
        return ServiceResult<SetMembershipBillingResponse>.Success(
            new SetMembershipBillingResponse(response, created, membership.NextBillingOn));
    }

    public async Task<ServiceResult> EndMembershipAsync(long id, EndMembershipRequest request)
    {
        var membership = await _dbContext.MemberMemberships.FirstOrDefaultAsync(x => x.Id == id && x.StudioId == _currentUser.StudioId);
        if (membership is null) return ServiceResult.NotFound("Member membership not found.", "A membership with this id does not exist.");
        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        if (!isAdmin && (!_currentUser.MemberId.HasValue || membership.MemberId != _currentUser.MemberId.Value))
            return ServiceResult.Forbidden("Membership access denied.", "A member can only end their own membership.");
        var today = await GetStudioTodayAsync();
        if (request.EndsOn <= membership.StartsOn || !isAdmin && request.EndsOn < today)
            return ServiceResult.Conflict("Invalid membership end date.", "The end date must be after the start date and members cannot backdate it.");

        membership.EndsOn = request.EndsOn;
        if (membership.NextBillingOn.HasValue && membership.NextBillingOn.Value >= request.EndsOn) membership.NextBillingOn = null;
        membership.UpdatedAt = DateTime.UtcNow;
        var pending = await _dbContext.MembershipPaymentObligations.FirstOrDefaultAsync(x =>
            x.MemberMembershipId == id && x.Status == "pending" && x.PeriodStartsOn < request.EndsOn && x.PeriodEndsOn > request.EndsOn);
        if (pending is not null)
        {
            pending.AmountDue = MembershipCycle.Prorate(pending.FullAmount, pending.PeriodStartsOn, pending.PeriodEndsOn, request.EndsOn);
            pending.UpdatedAt = DateTime.UtcNow;
        }
        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    private IQueryable<MemberMembership> QueryMemberships()
    {
        var query = _dbContext.MemberMemberships
            .AsNoTracking()
            .Where(membership => membership.StudioId == _currentUser.StudioId);

        if (_currentUser.IsMemberOnly)
        {
            var memberId = _currentUser.MemberId
                ?? throw new InvalidOperationException("Authenticated member is missing the member_id claim.");
            query = query.Where(membership => membership.MemberId == memberId);
        }

        return query;
    }

    private static IQueryable<MemberMembershipResponse> Project(
        IQueryable<MemberMembership> query,
        DateOnly today)
    {
        return query.Select(membership => new MemberMembershipResponse(
            membership.Id,
            membership.MemberId,
            membership.Member.FirstName + " " + membership.Member.LastName,
            membership.MembershipPlanId,
            membership.MembershipPlan.Name,
            membership.StartsOn,
            membership.EndsOn,
            membership.BillingStartsOn,
            membership.NextBillingOn,
            membership.StartsOn <= today
            && (!membership.EndsOn.HasValue || membership.EndsOn.Value > today)));
    }

    private async Task<ServiceResult?> ValidateRequestAsync(
        CreateMemberMembershipRequest request,
        long? ignoredMembershipId = null)
    {
        if (request.EndsOn.HasValue && request.EndsOn.Value <= request.StartsOn)
        {
            return ServiceResult.Conflict(
                "Invalid membership dates.",
                "Membership end date must be on or after its start date.");
        }
        if (request.NextBillingOn is { } firstBillingOn
            && (firstBillingOn < request.StartsOn
                || request.EndsOn.HasValue && firstBillingOn >= request.EndsOn.Value))
        {
            return ServiceResult.Conflict(
                "Invalid first billing date.",
                "The first billing date must be inside the membership period.");
        }

        if (!await _dbContext.Members.AnyAsync(member =>
            member.Id == request.MemberId && member.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Member does not exist.",
                "Membership must reference a member from the current studio.");
        }

        if (!await _dbContext.MembershipPlans.AnyAsync(plan =>
            plan.Id == request.MembershipPlanId && plan.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Membership plan does not exist.",
                "Membership must reference a plan from the current studio.");
        }

        var overlaps = await _dbContext.MemberMemberships.AnyAsync(membership =>
            membership.StudioId == _currentUser.StudioId
            && membership.MemberId == request.MemberId
            && (!ignoredMembershipId.HasValue || membership.Id != ignoredMembershipId.Value)
            && (!request.EndsOn.HasValue || membership.StartsOn < request.EndsOn.Value)
            && (!membership.EndsOn.HasValue || membership.EndsOn.Value > request.StartsOn));
        if (overlaps)
        {
            return ServiceResult.Conflict(
                "Membership periods overlap.",
                "This member already has a membership that overlaps the selected period.");
        }

        return null;
    }

    private async Task<DateOnly> GetStudioTodayAsync()
    {
        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        return DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
    }
}
