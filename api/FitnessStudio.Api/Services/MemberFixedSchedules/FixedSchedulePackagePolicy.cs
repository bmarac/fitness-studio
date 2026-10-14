using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Members;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MemberFixedSchedules;

internal static class FixedSchedulePackagePolicy
{
    public static async Task<bool> AllowsAssignmentAsync(
        FitnessStudioDbContext dbContext,
        long studioId,
        long memberId,
        DateOnly startsOn,
        DateOnly? targetValidUntil,
        long? ignoredAssignmentId = null)
    {
        var membership = await dbContext.MemberMemberships
            .AsNoTracking()
            .Where(item =>
                item.StudioId == studioId
                && item.MemberId == memberId
                && item.StartsOn <= startsOn
                && (!item.EndsOn.HasValue || startsOn < item.EndsOn.Value))
            .OrderByDescending(item => item.StartsOn)
            .Select(item => new
            {
                item.MembershipPlan.SessionLimit,
                item.MembershipPlan.SessionLimitPeriod
            })
            .FirstOrDefaultAsync();

        if (membership is null)
        {
            return false;
        }

        if (!membership.SessionLimit.HasValue)
        {
            return true;
        }

        if (membership.SessionLimitPeriod != "week")
        {
            return false;
        }

        var activeAssignments = await OverlappingActiveAssignments(
                dbContext,
                studioId,
                startsOn,
                targetValidUntil)
            .Where(item =>
                item.MemberId == memberId
                && (!ignoredAssignmentId.HasValue || item.Id != ignoredAssignmentId.Value))
            .CountAsync();

        return activeAssignments < membership.SessionLimit.Value;
    }

    public static async Task<List<AvailableFixedScheduleMemberResponse>>
        GetAvailableMembersAsync(
            FitnessStudioDbContext dbContext,
            long studioId,
            long recurringScheduleId,
            DateOnly startsOn,
            DateOnly? targetValidUntil)
    {
        var memberships = await dbContext.MemberMemberships
            .AsNoTracking()
            .Where(item =>
                item.StudioId == studioId
                && item.Member.Status == MemberStatuses.Active
                && item.StartsOn <= startsOn
                && (!item.EndsOn.HasValue || startsOn < item.EndsOn.Value))
            .OrderByDescending(item => item.StartsOn)
            .Select(item => new
            {
                item.MemberId,
                item.Member.FirstName,
                item.Member.LastName,
                item.Member.Email,
                item.Member.Status,
                item.MembershipPlan.SessionLimit,
                item.MembershipPlan.SessionLimitPeriod
            })
            .ToListAsync();

        var currentMemberships = memberships
            .GroupBy(item => item.MemberId)
            .Select(group => group.First())
            .ToList();
        var memberIds = currentMemberships.Select(item => item.MemberId).ToList();

        var assignedToTarget = await dbContext.MemberFixedSchedules
            .AsNoTracking()
            .Where(item =>
                item.StudioId == studioId
                && memberIds.Contains(item.MemberId)
                && item.RecurringScheduleId == recurringScheduleId
                && (item.Status == "active" || item.Status == "paused"))
            .Select(item => item.MemberId)
            .Distinct()
            .ToListAsync();
        var assignedToTargetIds = assignedToTarget.ToHashSet();

        var activeAssignmentCounts = await OverlappingActiveAssignments(
                dbContext,
                studioId,
                startsOn,
                targetValidUntil)
            .Where(item => memberIds.Contains(item.MemberId))
            .GroupBy(item => item.MemberId)
            .Select(group => new { MemberId = group.Key, Count = group.Count() })
            .ToDictionaryAsync(item => item.MemberId, item => item.Count);

        return currentMemberships
            .Where(item => !assignedToTargetIds.Contains(item.MemberId))
            .Where(item =>
                !item.SessionLimit.HasValue
                || (item.SessionLimitPeriod == "week"
                    && activeAssignmentCounts.GetValueOrDefault(item.MemberId)
                        < item.SessionLimit.Value))
            .OrderBy(item => item.LastName)
            .ThenBy(item => item.FirstName)
            .Select(item => new AvailableFixedScheduleMemberResponse(
                item.MemberId,
                item.FirstName,
                item.LastName,
                item.Email,
                item.Status))
            .ToList();
    }

    private static IQueryable<FitnessStudio.Api.Entities.MemberFixedSchedule> OverlappingActiveAssignments(
        FitnessStudioDbContext dbContext,
        long studioId,
        DateOnly startsOn,
        DateOnly? targetValidUntil)
    {
        return dbContext.MemberFixedSchedules
            .AsNoTracking()
            .Where(item =>
                item.StudioId == studioId
                && item.Status == "active"
                && (!item.EndsOn.HasValue || item.EndsOn.Value >= startsOn)
                && (!item.RecurringSchedule.ValidUntil.HasValue
                    || item.RecurringSchedule.ValidUntil.Value >= startsOn)
                && (!targetValidUntil.HasValue || item.StartsOn <= targetValidUntil.Value)
                && (!targetValidUntil.HasValue
                    || item.RecurringSchedule.ValidFrom <= targetValidUntil.Value));
    }
}
