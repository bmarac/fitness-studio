using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MembershipPlans;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipPlansServiceTests
{
    [Fact]
    public async Task ListAndGetAreSortedAndScopedToCurrentStudio()
    {
        await using var db = Database();
        db.MembershipPlans.AddRange(
            Plan(1, 1, "Unlimited"),
            Plan(2, 1, "Basic"),
            Plan(3, 2, "Foreign"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var list = await service.GetPlansAsync();
        var local = await service.GetPlanAsync(1);
        var foreign = await service.GetPlanAsync(3);

        Assert.Equal(["Basic", "Unlimited"], list.Select(item => item.Name));
        Assert.Equal(ServiceResultStatus.Success, local.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task CreateAssignsStudioAndNormalizesValues()
    {
        await using var db = Database();

        var result = await Service(db).CreatePlanAsync(Request(
            " Monthly ", " MONTH ", " ACTIVE ", " eur "));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var stored = Assert.Single(db.MembershipPlans);
        Assert.Equal(1, stored.StudioId);
        Assert.Equal("Monthly", stored.Name);
        Assert.Equal("Description", stored.Description);
        Assert.Equal("month", stored.SessionLimitPeriod);
        Assert.Equal("EUR", stored.Currency);
        Assert.Equal("active", stored.Status);
        Assert.Equal(stored.CreatedAt, stored.UpdatedAt);
    }

    [Theory]
    [InlineData("archived", 8, "month")]
    [InlineData("active", 8, null)]
    [InlineData("active", null, "month")]
    [InlineData("active", 8, "year")]
    public async Task CreateRejectsInvalidStatusOrSessionLimitPair(
        string status,
        int? limit,
        string? period)
    {
        await using var db = Database();
        var request = Request("Monthly", period, status);
        request.SessionLimit = limit;

        var result = await Service(db).CreatePlanAsync(request);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(db.MembershipPlans);
    }

    [Fact]
    public async Task DuplicateNameIsRejectedOnlyInsideCurrentStudio()
    {
        await using var db = Database();
        db.MembershipPlans.AddRange(Plan(1, 1, "Basic"), Plan(2, 2, "Foreign"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var duplicate = await service.CreatePlanAsync(Request("Basic"));
        var otherStudioName = await service.CreatePlanAsync(Request("Foreign"));

        Assert.Equal(ServiceResultStatus.Conflict, duplicate.Status);
        Assert.Equal(ServiceResultStatus.Success, otherStudioName.Status);
    }

    [Fact]
    public async Task UpdatePersistsValuesAndRejectsAnotherLocalName()
    {
        await using var db = Database();
        db.MembershipPlans.AddRange(Plan(1, 1, "Basic"), Plan(2, 1, "Premium"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var duplicate = await service.UpdatePlanAsync(1, Update("Premium"));
        var updated = await service.UpdatePlanAsync(
            1, Update(" Updated ", null, " INACTIVE ", " usd "));

        Assert.Equal(ServiceResultStatus.Conflict, duplicate.Status);
        Assert.Equal(ServiceResultStatus.Success, updated.Status);
        var stored = db.MembershipPlans.Find(1L)!;
        Assert.Equal("Updated", stored.Name);
        Assert.Null(stored.SessionLimit);
        Assert.Null(stored.SessionLimitPeriod);
        Assert.Equal("USD", stored.Currency);
        Assert.Equal("inactive", stored.Status);
    }

    [Fact]
    public async Task UpdateAndDeleteHideForeignOrMissingIds()
    {
        await using var db = Database();
        db.MembershipPlans.Add(Plan(3, 2, "Foreign"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var update = await service.UpdatePlanAsync(3, Update("Changed"));
        var delete = await service.DeletePlanAsync(99);

        Assert.Equal(ServiceResultStatus.NotFound, update.Status);
        Assert.Equal(ServiceResultStatus.NotFound, delete.Status);
        Assert.Single(db.MembershipPlans);
    }

    [Fact]
    public async Task DeleteRemovesPlanAndMapsRelatedDataConflict()
    {
        await using var normal = Database();
        normal.MembershipPlans.Add(Plan(1, 1, "Basic"));
        await normal.SaveChangesAsync();
        Assert.Equal(ServiceResultStatus.Success, (await Service(normal).DeletePlanAsync(1)).Status);
        Assert.Empty(normal.MembershipPlans);

        var options = Options();
        await using var conflict = new DeleteConflictDbContext(options);
        conflict.MembershipPlans.Add(Plan(2, 1, "Used"));
        await conflict.SaveChangesAsync();
        conflict.FailPlanDeletes = true;

        var result = await Service(conflict).DeletePlanAsync(2);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
    }

    private static DbContextOptions<FitnessStudioDbContext> Options() =>
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;

    private static FitnessStudioDbContext Database() => new(Options());

    private static MembershipPlansService Service(FitnessStudioDbContext db) =>
        new(db, new Context());

    private static MembershipPlan Plan(long id, long studioId, string name) => new()
    {
        Id = id,
        StudioId = studioId,
        Name = name,
        BillingPeriodMonths = 1,
        SessionLimit = 8,
        SessionLimitPeriod = "month",
        PriceAmount = 40,
        Currency = "EUR",
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static CreateMembershipPlanRequest Request(
        string name,
        string? period = "month",
        string status = "active",
        string currency = "EUR") => new()
        {
            Name = name,
            Description = " Description ",
            BillingPeriodMonths = 1,
            SessionLimit = period is null ? null : 8,
            SessionLimitPeriod = period,
            PriceAmount = 40,
            Currency = currency,
            Status = status
        };

    private static UpdateMembershipPlanRequest Update(
        string name,
        string? period = "month",
        string status = "active",
        string currency = "EUR") => new()
        {
            Name = name,
            Description = " Updated ",
            BillingPeriodMonths = 1,
            SessionLimit = period is null ? null : 10,
            SessionLimitPeriod = period,
            PriceAmount = 55,
            Currency = currency,
            Status = status
        };

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class DeleteConflictDbContext(DbContextOptions<FitnessStudioDbContext> options)
        : FitnessStudioDbContext(options)
    {
        public bool FailPlanDeletes { get; set; }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            if (FailPlanDeletes && ChangeTracker.Entries<MembershipPlan>()
                    .Any(entry => entry.State == EntityState.Deleted))
            {
                throw new DbUpdateException("Related memberships exist.");
            }

            return base.SaveChangesAsync(cancellationToken);
        }
    }
}
