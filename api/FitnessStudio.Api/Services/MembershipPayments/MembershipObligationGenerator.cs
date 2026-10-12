using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MembershipPayments;

public static class MembershipObligationGenerator
{
    public static async Task<int> GenerateDueAsync(
        FitnessStudioDbContext db,
        MemberMembership membership,
        PaymentSettingsResponse settings,
        DateOnly today,
        CancellationToken cancellationToken = default)
    {
        if (!membership.NextBillingOn.HasValue || !settings.IsComplete)
        {
            return 0;
        }

        var anchorDay = (membership.BillingStartsOn ?? membership.NextBillingOn.Value).Day;
        var created = 0;
        var dueStarts = MembershipCycle.DueStarts(
            membership.NextBillingOn.Value, today, anchorDay, membership.EndsOn);
        foreach (var periodStart in dueStarts)
        {
            var periodEnd = MembershipCycle.NextMonth(periodStart, anchorDay);
            var amountDue = membership.EndsOn is { } end && end < periodEnd
                ? MembershipCycle.Prorate(membership.MembershipPlan.PriceAmount, periodStart, periodEnd, end)
                : membership.MembershipPlan.PriceAmount;
            var exists = db.MembershipPaymentObligations.Local.Any(item =>
                             item.MemberMembershipId == membership.Id && item.PeriodStartsOn == periodStart)
                         || await db.MembershipPaymentObligations.AnyAsync(item =>
                             item.MemberMembershipId == membership.Id && item.PeriodStartsOn == periodStart,
                             cancellationToken);
            if (!exists)
            {
                var now = DateTime.UtcNow;
                db.MembershipPaymentObligations.Add(new MembershipPaymentObligation
                {
                    StudioId = membership.StudioId,
                    MemberMembershipId = membership.Id,
                    PeriodStartsOn = periodStart,
                    PeriodEndsOn = periodEnd,
                    DueOn = periodStart,
                    PlanName = membership.MembershipPlan.Name,
                    FullAmount = membership.MembershipPlan.PriceAmount,
                    AmountDue = amountDue,
                    Currency = membership.MembershipPlan.Currency,
                    Status = "pending",
                    RecipientName = settings.RecipientName,
                    Iban = settings.Iban,
                    PaymentModel = settings.PaymentModel,
                    PaymentReference = settings.PaymentReference,
                    PaymentDescription = settings.PaymentDescription,
                    CreatedAt = now,
                    UpdatedAt = now
                });
                created++;
            }

            var next = MembershipCycle.NextMonth(periodStart, anchorDay);
            membership.NextBillingOn = membership.EndsOn.HasValue && next >= membership.EndsOn.Value
                ? null
                : next;
            membership.UpdatedAt = DateTime.UtcNow;
        }

        return created;
    }
}
