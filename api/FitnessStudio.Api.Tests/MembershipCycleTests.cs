using FitnessStudio.Api.Services.MembershipPayments;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipCycleTests
{
    [Fact]
    public void NextMonth_PreservesOriginalAnchorAfterShortMonth()
    {
        var february = MembershipCycle.NextMonth(new DateOnly(2026, 1, 31), 31);
        var march = MembershipCycle.NextMonth(february, 31);

        Assert.Equal(new DateOnly(2026, 2, 28), february);
        Assert.Equal(new DateOnly(2026, 3, 31), march);
    }

    [Fact]
    public void Prorate_UsesExclusiveMembershipEnd()
    {
        var amount = MembershipCycle.Prorate(
            70m,
            new DateOnly(2026, 10, 11),
            new DateOnly(2026, 11, 11),
            new DateOnly(2026, 10, 26));

        Assert.Equal(33.87m, amount);
    }

    [Fact]
    public void DueStarts_ReturnsEveryRetroactiveCycleAndPreservesAnchor()
    {
        var starts = MembershipCycle.DueStarts(
            new DateOnly(2026, 1, 31),
            new DateOnly(2026, 3, 31),
            31);

        Assert.Equal(
            [
                new DateOnly(2026, 1, 31),
                new DateOnly(2026, 2, 28),
                new DateOnly(2026, 3, 31)
            ],
            starts);
    }
}
