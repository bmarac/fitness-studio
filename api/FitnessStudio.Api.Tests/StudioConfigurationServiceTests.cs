using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.StudioSettings;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class StudioConfigurationServiceTests
{
    [Fact]
    public async Task UpdateStoresAndReturnsTheCompleteConfiguration()
    {
        await using var db = CreateDatabase();
        db.Studios.Add(Studio(1));
        await db.SaveChangesAsync();
        var service = new StudioConfigurationService(db, new Context(1));

        var result = await service.UpdateAsync(ValidRequest());
        var loaded = await service.GetAsync();

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(9, await db.StudioSettings.CountAsync());
        Assert.True(loaded.JoinByCodeEnabled);
        Assert.Equal("STAY_FIT", loaded.JoinCode);
        Assert.Equal("Stay Fit d.o.o.", loaded.RecipientName);
        Assert.Equal("HR1210010051863000160", loaded.Iban);
        Assert.Equal([1, 3], loaded.MemberReminderDays);
        Assert.Equal([5], loaded.AdminReminderDays);
        Assert.Equal(new TimeOnly(9, 30), loaded.NotificationTime);
        Assert.True(loaded.IsPaymentComplete);
    }

    [Fact]
    public async Task DisablingJoinByCodeRemovesOnlyTheJoinCode()
    {
        await using var db = CreateDatabase();
        db.Studios.Add(Studio(1));
        await db.SaveChangesAsync();
        var service = new StudioConfigurationService(db, new Context(1));
        await service.UpdateAsync(ValidRequest());
        var request = ValidRequest();
        request.JoinByCodeEnabled = false;
        request.JoinCode = "LOCAL_VALUE_CAN_REMAIN";

        var result = await service.UpdateAsync(request);

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.DoesNotContain(
            db.StudioSettings,
            setting => setting.Setting == "join_code");
        Assert.Equal(8, await db.StudioSettings.CountAsync());
    }

    [Fact]
    public async Task InvalidRequestDoesNotPartiallyChangeStoredSettings()
    {
        await using var db = CreateDatabase();
        db.Studios.Add(Studio(1));
        db.StudioSettings.Add(new StudioSetting
        {
            StudioId = 1,
            Setting = "payment_recipient_name",
            Value = "Original recipient",
            ValueType = "string",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var service = new StudioConfigurationService(db, new Context(1));
        var request = ValidRequest();
        request.RecipientName = "Changed recipient";
        request.AdminReminderDays = [2, 2];

        var result = await service.UpdateAsync(request);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Single(db.StudioSettings);
        Assert.Equal("Original recipient", db.StudioSettings.Single().Value);
    }

    [Theory]
    [InlineData("invalid code", "HR1210010051863000160", false)]
    [InlineData("STAYFIT", "HR001", false)]
    [InlineData("STAYFIT", "HR1210010051863000160", true)]
    public async Task ValidatesCodeIbanAndReminderDays(
        string joinCode,
        string iban,
        bool invalidDays)
    {
        await using var db = CreateDatabase();
        db.Studios.Add(Studio(1));
        await db.SaveChangesAsync();
        var service = new StudioConfigurationService(db, new Context(1));
        var request = ValidRequest();
        request.JoinCode = joinCode;
        request.Iban = iban;
        if (invalidDays)
        {
            request.MemberReminderDays = [366];
        }

        var result = await service.UpdateAsync(request);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(db.StudioSettings);
    }

    [Fact]
    public async Task RejectsAJoinCodeOwnedByAnotherStudio()
    {
        await using var db = CreateDatabase();
        db.Studios.AddRange(Studio(1), Studio(2));
        db.StudioSettings.Add(new StudioSetting
        {
            StudioId = 2,
            Setting = "join_code",
            Value = "STAY_FIT",
            ValueType = "string",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var service = new StudioConfigurationService(db, new Context(1));

        var result = await service.UpdateAsync(ValidRequest());

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Single(db.StudioSettings);
    }

    private static UpdateStudioConfigurationRequest ValidRequest() => new()
    {
        JoinByCodeEnabled = true,
        JoinCode = " stay_fit ",
        RecipientName = " Stay Fit d.o.o. ",
        Iban = "HR12 1001 0051 8630 0016 0",
        PaymentModel = "hr00",
        PaymentReference = "123-2026",
        PaymentDescription = "Članarina",
        MemberReminderDays = [3, 1],
        AdminReminderDays = [5],
        NotificationTime = new TimeOnly(9, 30)
    };

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private static Studio Studio(long id) => new()
    {
        Id = id,
        Name = $"Studio {id}",
        Timezone = "Europe/Zagreb",
        Status = AuthStatuses.Active,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private sealed class Context(long studioId) : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => studioId;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } =
            new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
