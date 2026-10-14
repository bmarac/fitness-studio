using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MemberMemberships;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberMembershipsServiceTests
{
    [Fact]
    public async Task MembershipListUsesStudioDateAndRequiresMembershipToHaveStarted()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixture(db);
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(fixture.Studio.Timezone);
        var today = DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        db.MemberMemberships.AddRange(
            Membership(1, fixture, fixture.FirstPlan, today.AddDays(-1), null),
            Membership(2, fixture, fixture.SecondPlan, today.AddDays(1), null));
        await db.SaveChangesAsync();

        var memberships = await Service(db).GetMembershipsAsync();

        Assert.True(memberships.Single(item => item.Id == 1).IsActive);
        Assert.False(memberships.Single(item => item.Id == 2).IsActive);
    }

    [Fact]
    public async Task CreateRejectsOverlappingPeriodButAllowsTouchingBoundary()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixture(db);
        db.MemberMemberships.Add(Membership(
            1,
            fixture,
            fixture.FirstPlan,
            new DateOnly(2026, 10, 1),
            new DateOnly(2026, 10, 10)));
        await db.SaveChangesAsync();
        var service = Service(db);

        var overlap = await service.CreateMembershipAsync(new CreateMemberMembershipRequest
        {
            MemberId = fixture.Member.Id,
            MembershipPlanId = fixture.SecondPlan.Id,
            StartsOn = new DateOnly(2026, 10, 9),
            EndsOn = new DateOnly(2026, 10, 20)
        });
        var touching = await service.CreateMembershipAsync(new CreateMemberMembershipRequest
        {
            MemberId = fixture.Member.Id,
            MembershipPlanId = fixture.SecondPlan.Id,
            StartsOn = new DateOnly(2026, 10, 10),
            EndsOn = new DateOnly(2026, 10, 20)
        });

        Assert.Equal(ServiceResultStatus.Conflict, overlap.Status);
        Assert.Contains("overlaps", overlap.Error!.Detail);
        Assert.Equal(ServiceResultStatus.Success, touching.Status);
    }

    [Fact]
    public async Task UpdateChangesPlanAndDatesWithoutChangingBillingOrExistingObligations()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixture(db);
        var membership = Membership(
            1,
            fixture,
            fixture.FirstPlan,
            new DateOnly(2026, 10, 1),
            null);
        membership.BillingStartsOn = new DateOnly(2026, 10, 5);
        membership.NextBillingOn = new DateOnly(2026, 11, 5);
        var obligation = new MembershipPaymentObligation
        {
            Id = 1,
            Studio = fixture.Studio,
            StudioId = fixture.Studio.Id,
            MemberMembership = membership,
            MemberMembershipId = membership.Id,
            PeriodStartsOn = new DateOnly(2026, 10, 5),
            PeriodEndsOn = new DateOnly(2026, 11, 5),
            DueOn = new DateOnly(2026, 10, 5),
            PlanName = fixture.FirstPlan.Name,
            FullAmount = 40,
            AmountDue = 40,
            Currency = "EUR",
            Status = "pending",
            RecipientName = "Studio",
            Iban = "HR1723600001101234565",
            PaymentModel = "HR00",
            PaymentReference = "1",
            PaymentDescription = "Članarina",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        db.AddRange(membership, obligation);
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateMembershipAsync(1, new UpdateMemberMembershipRequest
        {
            MemberId = fixture.Member.Id,
            MembershipPlanId = fixture.SecondPlan.Id,
            StartsOn = new DateOnly(2026, 10, 1)
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(fixture.SecondPlan.Id, membership.MembershipPlanId);
        Assert.Equal(new DateOnly(2026, 10, 5), membership.BillingStartsOn);
        Assert.Equal(new DateOnly(2026, 11, 5), membership.NextBillingOn);
        Assert.Equal(fixture.FirstPlan.Name, obligation.PlanName);
        Assert.Equal(40, obligation.AmountDue);
    }

    [Fact]
    public async Task UpdateIgnoresCurrentMembershipWhenCheckingOverlap()
    {
        await using var db = CreateDatabase();
        var fixture = AddFixture(db);
        db.MemberMemberships.Add(Membership(
            1,
            fixture,
            fixture.FirstPlan,
            new DateOnly(2026, 10, 1),
            null));
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateMembershipAsync(1, new UpdateMemberMembershipRequest
        {
            MemberId = fixture.Member.Id,
            MembershipPlanId = fixture.SecondPlan.Id,
            StartsOn = new DateOnly(2026, 10, 1)
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
    }

    private static MemberMembershipsService Service(FitnessStudioDbContext db) =>
        new(db, new Context(), new PaymentSettings());

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static (Studio Studio, Member Member, MembershipPlan FirstPlan, MembershipPlan SecondPlan)
        AddFixture(FitnessStudioDbContext db)
    {
        var now = DateTime.UtcNow;
        var studio = new Studio
        {
            Id = 1,
            Name = "Studio",
            Timezone = "Europe/Zagreb",
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        var member = new Member
        {
            Id = 1,
            Studio = studio,
            StudioId = studio.Id,
            FirstName = "Ana",
            LastName = "Horvat",
            Email = "ana@example.test",
            Status = "active",
            CreatedAt = now,
            UpdatedAt = now
        };
        var first = Plan(1, "Osnovni", studio, now);
        var second = Plan(2, "Premium", studio, now);
        db.AddRange(studio, member, first, second);
        return (studio, member, first, second);
    }

    private static MembershipPlan Plan(long id, string name, Studio studio, DateTime now) => new()
    {
        Id = id,
        Studio = studio,
        StudioId = studio.Id,
        Name = name,
        BillingPeriodMonths = 1,
        PriceAmount = id * 40,
        Currency = "EUR",
        Status = "active",
        CreatedAt = now,
        UpdatedAt = now
    };

    private static MemberMembership Membership(
        long id,
        (Studio Studio, Member Member, MembershipPlan FirstPlan, MembershipPlan SecondPlan) fixture,
        MembershipPlan plan,
        DateOnly startsOn,
        DateOnly? endsOn) => new()
    {
        Id = id,
        Studio = fixture.Studio,
        StudioId = fixture.Studio.Id,
        Member = fixture.Member,
        MemberId = fixture.Member.Id,
        MembershipPlan = plan,
        MembershipPlanId = plan.Id,
        StartsOn = startsOn,
        EndsOn = endsOn,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.test";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class PaymentSettings : IPaymentSettingsService
    {
        public Task<PaymentSettingsResponse> GetAsync(long? studioId = null) =>
            Task.FromResult(new PaymentSettingsResponse(
                "", "", "", "", "", [], [], new TimeOnly(9, 0), false));

        public Task<ServiceResult<PaymentSettingsResponse>> UpdateAsync(
            UpdatePaymentSettingsRequest request) => throw new NotSupportedException();
    }
}
