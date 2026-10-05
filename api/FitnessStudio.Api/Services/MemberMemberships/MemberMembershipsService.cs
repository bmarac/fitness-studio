using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MemberMemberships;

public class MemberMembershipsService : IMemberMembershipsService
{
    private static readonly HashSet<string> AllowedStatuses =
        ["active", "expired", "paused", "cancelled"];

    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MemberMembershipsService(FitnessStudioDbContext dbContext, ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public Task<List<MemberMembershipResponse>> GetMembershipsAsync()
    {
        return Project(QueryMemberships()
            .OrderByDescending(membership => membership.StartsOn))
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
                    && membership.Status == "active"
                    && membership.StartsOn <= today
                    && membership.EndsOn >= today)
                .OrderByDescending(membership => membership.StartsOn))
            .FirstOrDefaultAsync();
    }

    public async Task<ServiceResult<MemberMembershipResponse>> GetMembershipAsync(long id)
    {
        var membership = await Project(QueryMemberships().Where(item => item.Id == id))
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
            Status = Normalize(request.Status),
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

        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return validationResult;
        }

        membership.MemberId = request.MemberId;
        membership.MembershipPlanId = request.MembershipPlanId;
        membership.StartsOn = request.StartsOn;
        membership.EndsOn = request.EndsOn;
        membership.Status = Normalize(request.Status);
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

    private static IQueryable<MemberMembershipResponse> Project(IQueryable<MemberMembership> query)
    {
        return query.Select(membership => new MemberMembershipResponse(
            membership.Id,
            membership.MemberId,
            membership.Member.FirstName + " " + membership.Member.LastName,
            membership.MembershipPlanId,
            membership.MembershipPlan.Name,
            membership.StartsOn,
            membership.EndsOn,
            membership.Status));
    }

    private async Task<ServiceResult?> ValidateRequestAsync(CreateMemberMembershipRequest request)
    {
        if (request.EndsOn < request.StartsOn)
        {
            return ServiceResult.Conflict(
                "Invalid membership dates.",
                "Membership end date must be on or after its start date.");
        }

        if (!AllowedStatuses.Contains(Normalize(request.Status)))
        {
            return ServiceResult.Conflict(
                "Invalid membership status.",
                "Status must be active, expired, paused or cancelled.");
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

        return null;
    }

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();

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
