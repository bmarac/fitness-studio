using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.PaymentSettings;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class PaymentSettingsServiceTests
{
    [Fact]
    public async Task GetReturnsDefaultsForCurrentStudio()
    {
        await using var db = Database();
        db.StudioSettings.Add(Setting(2, "payment_recipient_name", "Foreign studio"));
        await db.SaveChangesAsync();

        var result = await Service(db).GetAsync();

        Assert.Equal(string.Empty, result.RecipientName);
        Assert.Equal("HR00", result.PaymentModel);
        Assert.Equal([0, 1], result.MemberReminderDays);
        Assert.Equal([2], result.AdminReminderDays);
        Assert.Equal(new TimeOnly(9, 0), result.NotificationTime);
        Assert.False(result.IsComplete);
    }

    [Fact]
    public async Task GetUsesRequestedStudioAndParsesStoredValues()
    {
        await using var db = Database();
        db.StudioSettings.AddRange(
            Setting(2, "payment_recipient_name", "Studio Two"),
            Setting(2, "payment_iban", "HR1210010051863000160"),
            Setting(2, "payment_reference", "MEMBER"),
            Setting(2, "payment_description", "Membership"),
            Setting(2, "payment_member_reminder_days", "7,0,2"),
            Setting(2, "payment_admin_reminder_days", "5,1"),
            Setting(2, "payment_notification_time", "14:30"));
        await db.SaveChangesAsync();

        var result = await Service(db).GetAsync(2);

        Assert.Equal("Studio Two", result.RecipientName);
        Assert.Equal([0, 2, 7], result.MemberReminderDays);
        Assert.Equal([1, 5], result.AdminReminderDays);
        Assert.Equal(new TimeOnly(14, 30), result.NotificationTime);
        Assert.True(result.IsComplete);
    }

    [Fact]
    public async Task UpdateRejectsInvalidIban()
    {
        await using var db = Database();
        var request = ValidRequest();
        request.Iban = "HR001234";

        var result = await Service(db).UpdateAsync(request);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Invalid IBAN.", result.Error?.Title);
        Assert.Empty(db.StudioSettings);
    }

    [Theory]
    [InlineData("empty")]
    [InlineData("duplicate")]
    [InlineData("negative")]
    [InlineData("too-large")]
    public async Task UpdateRejectsInvalidReminderDays(string scenario)
    {
        await using var db = Database();
        var request = ValidRequest();
        request.MemberReminderDays = scenario switch
        {
            "empty" => [],
            "duplicate" => [1, 1],
            "negative" => [-1],
            _ => [366]
        };

        var result = await Service(db).UpdateAsync(request);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Invalid reminder days.", result.Error?.Title);
        Assert.Empty(db.StudioSettings);
    }

    [Fact]
    public async Task UpdateNormalizesAndUpsertsOnlyCurrentStudioSettings()
    {
        await using var db = Database();
        db.StudioSettings.AddRange(
            Setting(1, "payment_model", "HR01"),
            Setting(2, "payment_model", "HR99"));
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateAsync(ValidRequest());

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.NotNull(result.Value);
        Assert.True(result.Value.IsComplete);
        Assert.Equal("Fitness Studio", result.Value.RecipientName);
        Assert.Equal("HR00", result.Value.PaymentModel);
        Assert.Equal([0, 2, 7], result.Value.MemberReminderDays);
        Assert.Equal([1, 5], result.Value.AdminReminderDays);
        Assert.Equal(8, await db.StudioSettings.CountAsync(x => x.StudioId == 1));
        Assert.Equal("HR99", (await db.StudioSettings.SingleAsync(
            x => x.StudioId == 2 && x.Setting == "payment_model")).Value);
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static PaymentSettingsService Service(FitnessStudioDbContext db) =>
        new(db, new Context());

    private static StudioSetting Setting(long studioId, string key, string value) => new()
    {
        StudioId = studioId,
        Setting = key,
        Value = value,
        ValueType = "string",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static UpdatePaymentSettingsRequest ValidRequest() => new()
    {
        RecipientName = " Fitness Studio ",
        Iban = "hr12 1001 0051 8630 0016 0",
        PaymentModel = " hr00 ",
        PaymentReference = " MEMBER-123 ",
        PaymentDescription = " Membership fee ",
        MemberReminderDays = [7, 0, 2],
        AdminReminderDays = [5, 1],
        NotificationTime = new TimeOnly(8, 45)
    };

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>();
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
