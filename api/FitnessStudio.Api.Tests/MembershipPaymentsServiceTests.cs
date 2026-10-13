using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MembershipPayments;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipPaymentsServiceTests
{
    [Fact]
    public async Task QueriesAreScopedAndAdministrativeFiltersAndSummaryAreApplied()
    {
        await using var db = CreateDatabase();
        AddPayment(db, 1, 1, 1, "pending", new DateOnly(2099, 1, 1));
        AddPayment(db, 2, 1, 2, "reported", new DateOnly(2020, 1, 1));
        AddPayment(db, 3, 1, 1, "paid", new DateOnly(2020, 1, 1));
        AddPayment(db, 4, 2, 1, "pending", new DateOnly(2020, 1, 1));
        await db.SaveChangesAsync();
        var memberService = new MembershipPaymentsService(db, new Context(1, 1, false));
        var adminService = new MembershipPaymentsService(db, new Context(1, null, true));

        var mine = await memberService.GetMineAsync();
        var reported = await adminService.GetAllAsync("reported", 2);
        var summary = await adminService.GetSummaryAsync();

        Assert.Equal([1L, 3L], mine.Select(x => x.Id).Order());
        Assert.Single(reported);
        Assert.Equal(2, reported[0].Id);
        Assert.Equal(new MembershipPaymentSummaryResponse(1, 1, 0, 1), summary);
    }

    [Fact]
    public async Task MemberCanReportOnlyOwnPendingPayment()
    {
        await using var db = CreateDatabase();
        AddPayment(db, 1, 1, 1, "pending", new DateOnly(2026, 10, 1));
        AddPayment(db, 2, 1, 2, "pending", new DateOnly(2026, 10, 1));
        await db.SaveChangesAsync();
        var service = new MembershipPaymentsService(db, new Context(1, 1, false));

        var reported = await service.ReportAsync(1);
        var repeated = await service.ReportAsync(1);
        var otherMember = await service.ReportAsync(2);

        Assert.Equal(ServiceResultStatus.Success, reported.Status);
        Assert.Equal("reported", db.MembershipPaymentObligations.Find(1L)!.Status);
        Assert.NotNull(db.MembershipPaymentObligations.Find(1L)!.ReportedAt);
        Assert.Equal(ServiceResultStatus.Conflict, repeated.Status);
        Assert.Equal(ServiceResultStatus.NotFound, otherMember.Status);
    }

    [Fact]
    public async Task AdministrativeTransitionsEnforceRolesAndStateMachine()
    {
        await using var db = CreateDatabase();
        AddPayment(db, 1, 1, 1, "reported", new DateOnly(2026, 10, 1));
        await db.SaveChangesAsync();
        var member = new MembershipPaymentsService(db, new Context(1, 1, false));
        var admin = new MembershipPaymentsService(db, new Context(1, null, true));

        Assert.Equal(ServiceResultStatus.Forbidden, (await member.ConfirmAsync(1)).Status);
        Assert.Equal(ServiceResultStatus.Success, (await admin.RejectReportAsync(1)).Status);
        Assert.Equal("pending", db.MembershipPaymentObligations.Find(1L)!.Status);
        Assert.Equal(ServiceResultStatus.Success, (await admin.ConfirmAsync(1)).Status);
        Assert.Equal("paid", db.MembershipPaymentObligations.Find(1L)!.Status);
        Assert.Equal(ServiceResultStatus.Success, (await admin.ReopenAsync(1)).Status);
        Assert.Equal("pending", db.MembershipPaymentObligations.Find(1L)!.Status);
        Assert.Equal(ServiceResultStatus.Conflict, (await admin.ReopenAsync(1)).Status);
    }

    [Fact]
    public async Task Hub3PayloadUsesAuthorizedPaymentAndExpectedAmount()
    {
        await using var db = CreateDatabase();
        AddPayment(db, 1, 1, 1, "pending", new DateOnly(2026, 10, 1), 70.25m);
        AddPayment(db, 2, 1, 2, "pending", new DateOnly(2026, 10, 1));
        await db.SaveChangesAsync();
        var service = new MembershipPaymentsService(db, new Context(1, 1, false));

        var own = await service.GetHub3PayloadAsync(1);
        var foreign = await service.GetHub3PayloadAsync(2);

        Assert.Equal(ServiceResultStatus.Success, own.Status);
        Assert.Contains("HRVHUB30\nEUR\n000000000007025\n", own.Value);
        Assert.Contains("Ana Member", own.Value);
        Assert.Contains("HR1723600001101234565", own.Value);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task ObligationGeneratorCreatesDuePeriodsOnceAndProratesFinalPeriod()
    {
        await using var db = CreateDatabase();
        var membership = AddMembership(db, 1, 1, 1);
        membership.BillingStartsOn = new DateOnly(2026, 1, 31);
        membership.NextBillingOn = new DateOnly(2026, 1, 31);
        membership.EndsOn = new DateOnly(2026, 3, 15);
        await db.SaveChangesAsync();
        var settings = Settings();

        var created = await MembershipObligationGenerator.GenerateDueAsync(db, membership, settings, new DateOnly(2026, 3, 31));
        await db.SaveChangesAsync();
        var repeated = await MembershipObligationGenerator.GenerateDueAsync(db, membership, settings, new DateOnly(2026, 3, 31));

        Assert.Equal(2, created);
        Assert.Equal(0, repeated);
        Assert.Equal(2, db.MembershipPaymentObligations.Count());
        Assert.Equal(33.87m, db.MembershipPaymentObligations.Single(x => x.PeriodStartsOn == new DateOnly(2026, 2, 28)).AmountDue);
        Assert.Null(membership.NextBillingOn);
    }

    [Fact]
    public async Task ObligationGeneratorSkipsIncompleteSettings()
    {
        await using var db = CreateDatabase();
        var membership = AddMembership(db, 1, 1, 1);
        membership.NextBillingOn = new DateOnly(2026, 1, 1);

        var created = await MembershipObligationGenerator.GenerateDueAsync(
            db, membership, Settings() with { IsComplete = false }, new DateOnly(2026, 1, 1));

        Assert.Equal(0, created);
        Assert.Empty(db.MembershipPaymentObligations);
    }

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static MembershipPaymentObligation AddPayment(
        FitnessStudioDbContext db, long id, long studioId, long memberId,
        string status, DateOnly dueOn, decimal amount = 70m)
    {
        var membership = AddMembership(db, id, studioId, memberId);
        var payment = new MembershipPaymentObligation
        {
            Id = id,
            StudioId = studioId,
            MemberMembershipId = membership.Id,
            MemberMembership = membership,
            Studio = membership.Studio,
            PeriodStartsOn = new DateOnly(2026, 10, 1),
            PeriodEndsOn = new DateOnly(2026, 11, 1),
            DueOn = dueOn,
            PlanName = "Mjesečni",
            FullAmount = 70m,
            AmountDue = amount,
            Currency = "EUR",
            Status = status,
            RecipientName = "Studio",
            Iban = "HR1723600001101234565",
            PaymentModel = "HR00",
            PaymentReference = "123",
            PaymentDescription = "Članarina",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        db.MembershipPaymentObligations.Add(payment);
        return payment;
    }

    private static MemberMembership AddMembership(FitnessStudioDbContext db, long id, long studioId, long memberId)
    {
        var studio = db.Studios.Local.FirstOrDefault(x => x.Id == studioId) ?? new Studio
        {
            Id = studioId,
            Name = $"Studio {studioId}",
            Timezone = "Europe/Zagreb",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        if (db.Entry(studio).State == EntityState.Detached) db.Studios.Add(studio);
        var member = db.Members.Local.FirstOrDefault(x => x.Id == memberId) ?? new Member
        {
            Id = memberId,
            StudioId = studioId,
            Studio = studio,
            FirstName = memberId == 1 ? "Ana" : "Other",
            LastName = "Member",
            Email = $"member{memberId}@example.test",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        if (db.Entry(member).State == EntityState.Detached) db.Members.Add(member);
        var plan = new MembershipPlan
        {
            Id = id,
            StudioId = studioId,
            Studio = studio,
            Name = "Mjesečni",
            BillingPeriodMonths = 1,
            PriceAmount = 70m,
            Currency = "EUR",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var membership = new MemberMembership
        {
            Id = id,
            StudioId = studioId,
            Studio = studio,
            MemberId = memberId,
            Member = member,
            MembershipPlanId = plan.Id,
            MembershipPlan = plan,
            StartsOn = new DateOnly(2026, 1, 1),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        db.MemberMemberships.Add(membership);
        return membership;
    }

    private static PaymentSettingsResponse Settings() => new(
        "Studio", "HR1723600001101234565", "HR00", "123", "Članarina",
        [0, 1], [2], new TimeOnly(9, 0), true);

    private sealed class Context(long studioId, long? memberId, bool admin) : ICurrentUserContext
    {
        public long UserId => 99;
        public string Email => "user@example.test";
        public long StudioId => studioId;
        public long? MemberId => memberId;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = admin ? new HashSet<string> { AuthRoles.Admin } : new HashSet<string> { AuthRoles.Member };
        public bool IsMemberOnly => !admin;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
