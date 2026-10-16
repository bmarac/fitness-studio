using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MembershipPayments;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembershipBillingProcessorTests
{
    [Fact]
    public async Task ProcessesOnlyActiveStudiosWithCompletePaymentSettings()
    {
        await using var db = Database();
        db.Studios.AddRange(
            Studio(1, "active"),
            Studio(2, "inactive"));
        await db.SaveChangesAsync();
        var settings = new FakePaymentSettingsService
        {
            Response = PaymentSettings(isComplete: false)
        };

        await new MembershipBillingProcessor(db, settings).ProcessAsync();

        Assert.Equal([1L], settings.RequestedStudioIds);
        Assert.Empty(db.MembershipPaymentObligations);
        Assert.Empty(db.AppNotifications);
    }

    [Fact]
    public async Task GeneratesDueObligationAndMemberAndAdminNotificationsOnce()
    {
        await using var db = Database();
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        SeedMembership(db, today);
        await db.SaveChangesAsync();
        var processor = new MembershipBillingProcessor(
            db,
            new FakePaymentSettingsService
            {
                Response = PaymentSettings(isComplete: true)
            });

        await processor.ProcessAsync();
        await processor.ProcessAsync();

        var obligation = Assert.Single(db.MembershipPaymentObligations);
        Assert.Equal(today, obligation.DueOn);
        Assert.Equal(49.90m, obligation.AmountDue);
        Assert.Equal("pending", obligation.Status);
        Assert.Equal("Fitness Studio", obligation.RecipientName);
        Assert.Equal(today.AddMonths(1), db.MemberMemberships.Single().NextBillingOn);

        var notifications = await db.AppNotifications
            .OrderBy(item => item.AppUserId)
            .ToListAsync();
        Assert.Equal(2, notifications.Count);
        Assert.Equal(["member_payment_reminder", "admin_payment_reminder"],
            notifications.Select(item => item.NotificationType));
        Assert.All(notifications, item => Assert.Equal(0, item.DayOffset));
        Assert.Equal([101L, 102L], notifications.Select(item => item.AppUserId));
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static Studio Studio(long id, string status) => new()
    {
        Id = id,
        Name = $"Studio {id}",
        Timezone = "UTC",
        Status = status,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static PaymentSettingsResponse PaymentSettings(bool isComplete) => new(
        "Fitness Studio",
        "HR1210010051863000160",
        "HR00",
        "MEMBER",
        "Membership fee",
        [0],
        [0],
        new TimeOnly(0, 0),
        isComplete);

    private static void SeedMembership(FitnessStudioDbContext db, DateOnly today)
    {
        var studio = Studio(1, "active");
        var memberUser = User(101, "member@example.com");
        var adminUser = User(102, "admin@example.com");
        var member = new Member
        {
            Id = 11,
            StudioId = 1,
            FirstName = "Ana",
            LastName = "Horvat",
            Email = memberUser.Email,
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            Studio = studio
        };
        var memberLink = new AppUserStudio
        {
            Id = 201,
            AppUserId = memberUser.Id,
            AppUser = memberUser,
            StudioId = studio.Id,
            Studio = studio,
            MemberId = member.Id,
            Member = member,
            Status = "active",
            JoinedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        member.AppUserStudio = memberLink;
        var adminLink = new AppUserStudio
        {
            Id = 202,
            AppUserId = adminUser.Id,
            AppUser = adminUser,
            StudioId = studio.Id,
            Studio = studio,
            Status = "active",
            JoinedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var adminRole = new AppUserRole
        {
            AppUserStudioId = adminLink.Id,
            AppUserStudio = adminLink,
            Role = "admin",
            CreatedAt = DateTime.UtcNow
        };
        var plan = new MembershipPlan
        {
            Id = 31,
            StudioId = studio.Id,
            Studio = studio,
            Name = "Monthly",
            BillingPeriodMonths = 1,
            PriceAmount = 49.90m,
            Currency = "EUR",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var membership = new MemberMembership
        {
            Id = 41,
            StudioId = studio.Id,
            Studio = studio,
            MemberId = member.Id,
            Member = member,
            MembershipPlanId = plan.Id,
            MembershipPlan = plan,
            StartsOn = today,
            BillingStartsOn = today,
            NextBillingOn = today,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        db.AddRange(
            studio,
            memberUser,
            adminUser,
            member,
            memberLink,
            adminLink,
            adminRole,
            plan,
            membership);
    }

    private static AppUser User(long id, string email) => new()
    {
        Id = id,
        Email = email,
        PasswordHash = "hash",
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private sealed class FakePaymentSettingsService : IPaymentSettingsService
    {
        public PaymentSettingsResponse Response { get; set; } = null!;
        public List<long> RequestedStudioIds { get; } = [];

        public Task<PaymentSettingsResponse> GetAsync(long? studioId = null)
        {
            RequestedStudioIds.Add(studioId!.Value);
            return Task.FromResult(Response);
        }

        public Task<ServiceResult<PaymentSettingsResponse>> UpdateAsync(
            UpdatePaymentSettingsRequest request) => throw new NotSupportedException();
    }
}
