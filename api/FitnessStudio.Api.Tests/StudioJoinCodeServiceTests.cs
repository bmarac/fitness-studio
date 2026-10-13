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

public class StudioJoinCodeServiceTests
{
    [Fact]
    public async Task JoinCodeIsNormalizedChangedAndDeletedAsASetting()
    {
        await using var db = CreateDatabase();
        db.Studios.AddRange(Studio(1), Studio(2));
        await db.SaveChangesAsync();
        var service = new StudioSettingsService(db, new Context(1));

        var created = await service.UpsertSettingAsync("join_code", new UpsertStudioSettingRequest
        {
            Value = " stay_fit ", ValueType = "string"
        });
        var changed = await service.UpsertSettingAsync("join_code", new UpsertStudioSettingRequest
        {
            Value = "new-code", ValueType = "string"
        });
        var deleted = await service.DeleteSettingAsync("join_code");

        Assert.Equal("STAY_FIT", created.Value!.Value);
        Assert.Equal("NEW-CODE", changed.Value!.Value);
        Assert.Equal(ServiceResultStatus.Success, deleted.Status);
        Assert.Empty(db.StudioSettings);
    }

    [Fact]
    public async Task JoinCodesAreCaseInsensitiveAndGloballyUnique()
    {
        await using var db = CreateDatabase();
        db.Studios.AddRange(Studio(1), Studio(2));
        db.StudioSettings.Add(new StudioSetting
        {
            StudioId = 2, Setting = "join_code", Value = "TAKEN", ValueType = "string"
        });
        await db.SaveChangesAsync();
        var service = new StudioSettingsService(db, new Context(1));

        var duplicate = await service.UpsertSettingAsync("join_code", new UpsertStudioSettingRequest
        {
            Value = " taken ", ValueType = "string"
        });
        var invalid = await service.UpsertSettingAsync("join_code", new UpsertStudioSettingRequest
        {
            Value = "no spaces", ValueType = "string"
        });

        Assert.Equal(ServiceResultStatus.Conflict, duplicate.Status);
        Assert.Equal(ServiceResultStatus.Conflict, invalid.Status);
    }

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static Studio Studio(long id) => new()
    {
        Id = id, Name = $"Studio {id}", Timezone = "Europe/Zagreb", Status = AuthStatuses.Active,
        CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow
    };

    private sealed class Context(long studioId) : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => studioId;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
