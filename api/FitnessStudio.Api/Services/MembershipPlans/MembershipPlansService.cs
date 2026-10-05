using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MembershipPlans;

public class MembershipPlansService : IMembershipPlansService
{
    private static readonly HashSet<string> AllowedPeriods = ["week", "month", "membership"];
    private static readonly HashSet<string> AllowedStatuses = ["active", "inactive"];
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MembershipPlansService(FitnessStudioDbContext dbContext, ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public Task<List<MembershipPlanResponse>> GetPlansAsync()
    {
        return QueryPlans()
            .OrderBy(plan => plan.Name)
            .Select(plan => new MembershipPlanResponse(
                plan.Id,
                plan.Name,
                plan.Description,
                plan.DurationDays,
                plan.SessionLimit,
                plan.SessionLimitPeriod,
                plan.PriceAmount,
                plan.Currency,
                plan.Status))
            .ToListAsync();
    }

    public async Task<ServiceResult<MembershipPlanResponse>> GetPlanAsync(long id)
    {
        var plan = await QueryPlans().FirstOrDefaultAsync(plan => plan.Id == id);

        return plan is null
            ? ServiceResult<MembershipPlanResponse>.NotFound(
                "Membership plan not found.",
                "A membership plan with this id does not exist.")
            : ServiceResult<MembershipPlanResponse>.Success(ToResponse(plan));
    }

    public async Task<ServiceResult<MembershipPlanResponse>> CreatePlanAsync(CreateMembershipPlanRequest request)
    {
        var validationResult = await ValidateRequestAsync(request);
        if (validationResult is not null)
        {
            return new ServiceResult<MembershipPlanResponse>(
                validationResult.Status,
                default,
                validationResult.Error);
        }

        var now = DateTime.UtcNow;
        var plan = new MembershipPlan
        {
            StudioId = _currentUser.StudioId,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            DurationDays = request.DurationDays,
            SessionLimit = request.SessionLimit,
            SessionLimitPeriod = NormalizeOptional(request.SessionLimitPeriod),
            PriceAmount = request.PriceAmount,
            Currency = request.Currency.Trim().ToUpperInvariant(),
            Status = request.Status.Trim().ToLowerInvariant(),
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.MembershipPlans.Add(plan);
        await _dbContext.SaveChangesAsync();

        return ServiceResult<MembershipPlanResponse>.Success(ToResponse(plan));
    }

    public async Task<ServiceResult> UpdatePlanAsync(long id, UpdateMembershipPlanRequest request)
    {
        var plan = await QueryPlans().FirstOrDefaultAsync(plan => plan.Id == id);
        if (plan is null)
        {
            return ServiceResult.NotFound(
                "Membership plan not found.",
                "A membership plan with this id does not exist.");
        }

        var validationResult = await ValidateRequestAsync(request, id);
        if (validationResult is not null)
        {
            return validationResult;
        }

        plan.Name = request.Name.Trim();
        plan.Description = request.Description?.Trim();
        plan.DurationDays = request.DurationDays;
        plan.SessionLimit = request.SessionLimit;
        plan.SessionLimitPeriod = NormalizeOptional(request.SessionLimitPeriod);
        plan.PriceAmount = request.PriceAmount;
        plan.Currency = request.Currency.Trim().ToUpperInvariant();
        plan.Status = request.Status.Trim().ToLowerInvariant();
        plan.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeletePlanAsync(long id)
    {
        var plan = await QueryPlans().FirstOrDefaultAsync(plan => plan.Id == id);
        if (plan is null)
        {
            return ServiceResult.NotFound(
                "Membership plan not found.",
                "A membership plan with this id does not exist.");
        }

        _dbContext.MembershipPlans.Remove(plan);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Membership plan cannot be deleted.",
                "Membership plan cannot be deleted because related memberships exist.");
        }

        return ServiceResult.Success();
    }

    private IQueryable<MembershipPlan> QueryPlans()
    {
        return _dbContext.MembershipPlans.Where(plan => plan.StudioId == _currentUser.StudioId);
    }

    private async Task<ServiceResult?> ValidateRequestAsync(
        CreateMembershipPlanRequest request,
        long? ignoredId = null)
    {
        var status = request.Status.Trim().ToLowerInvariant();
        var period = NormalizeOptional(request.SessionLimitPeriod);

        if (!AllowedStatuses.Contains(status))
        {
            return ServiceResult.Conflict("Invalid membership plan status.", "Status must be active or inactive.");
        }

        if ((request.SessionLimit.HasValue && period is null)
            || (!request.SessionLimit.HasValue && period is not null)
            || (period is not null && !AllowedPeriods.Contains(period)))
        {
            return ServiceResult.Conflict(
                "Invalid membership session limit.",
                "Session limit and period must be supplied together; period must be week, month or membership.");
        }

        var name = request.Name.Trim();
        if (await QueryPlans().AnyAsync(plan =>
            plan.Name == name && (!ignoredId.HasValue || plan.Id != ignoredId.Value)))
        {
            return ServiceResult.Conflict(
                "Membership plan name already exists.",
                "A membership plan with this name already exists in the current studio.");
        }

        return null;
    }

    private static string? NormalizeOptional(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim().ToLowerInvariant();
    }

    private static MembershipPlanResponse ToResponse(MembershipPlan plan)
    {
        return new MembershipPlanResponse(
            plan.Id,
            plan.Name,
            plan.Description,
            plan.DurationDays,
            plan.SessionLimit,
            plan.SessionLimitPeriod,
            plan.PriceAmount,
            plan.Currency,
            plan.Status);
    }
}
