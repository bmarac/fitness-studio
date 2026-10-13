namespace FitnessStudio.Api.Services.MembershipPayments;

public static class MembershipCycle
{
    public static DateOnly NextMonth(DateOnly current, int anchorDay)
    {
        var first = new DateOnly(current.Year, current.Month, 1).AddMonths(1);
        return new DateOnly(first.Year, first.Month, Math.Min(anchorDay, DateTime.DaysInMonth(first.Year, first.Month)));
    }

    public static decimal Prorate(decimal fullAmount, DateOnly periodStart, DateOnly periodEnd, DateOnly membershipEnd)
    {
        if (membershipEnd >= periodEnd) return fullAmount;
        var totalDays = periodEnd.DayNumber - periodStart.DayNumber;
        var usedDays = Math.Max(0, membershipEnd.DayNumber - periodStart.DayNumber);
        return Math.Round(fullAmount * usedDays / totalDays, 2, MidpointRounding.AwayFromZero);
    }

    public static (DateOnly StartsOn, DateOnly EndsOnExclusive)? FindContainingPeriod(
        DateOnly billingStartsOn,
        DateOnly date)
    {
        if (date < billingStartsOn)
        {
            return null;
        }

        var anchorDay = billingStartsOn.Day;
        var periodStart = billingStartsOn;
        while (true)
        {
            var periodEnd = NextMonth(periodStart, anchorDay);
            if (date < periodEnd)
            {
                return (periodStart, periodEnd);
            }

            periodStart = periodEnd;
        }
    }

    public static IReadOnlyList<DateOnly> DueStarts(
        DateOnly nextBillingOn,
        DateOnly today,
        int anchorDay,
        DateOnly? membershipEnd = null)
    {
        var result = new List<DateOnly>();
        var current = nextBillingOn;
        while (current <= today && (!membershipEnd.HasValue || current < membershipEnd.Value))
        {
            result.Add(current);
            current = NextMonth(current, anchorDay);
        }

        return result;
    }
}
