using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MeasurementParameters;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MeasurementParameters;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MeasurementParametersServiceTests
{
    [Fact]
    public async Task ListIsStudioScopedAndHidesInactiveParametersFromNonAdmins()
    {
        await using var db = Database();
        db.MeasurementParameters.AddRange(
            Parameter(1, 1, "weight", "active", 2),
            Parameter(2, 1, "height", "inactive", 1),
            Parameter(3, 2, "foreign", "active", 0));
        await db.SaveChangesAsync();

        var member = await Service(db, AuthRoles.Member).GetParametersAsync();
        var admin = await Service(db, AuthRoles.Admin).GetParametersAsync();

        Assert.Equal(["weight"], member.Select(item => item.Code));
        Assert.Equal(["height", "weight"], admin.Select(item => item.Code));
    }

    [Fact]
    public async Task CreateGeneratesNormalizedUniqueCodeInsideCurrentStudio()
    {
        await using var db = Database();
        db.MeasurementParameters.AddRange(
            Parameter(1, 1, "tezina"),
            Parameter(2, 2, "tezina_2"));
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Admin);

        var created = await service.CreateParameterAsync(new CreateMeasurementParameterRequest
        {
            Name = " Težina ", Unit = " kg ", SortOrder = 1, Status = " ACTIVE "
        });
        var second = await service.CreateParameterAsync(new CreateMeasurementParameterRequest
        {
            Name = "Težina", SortOrder = 2, Status = "active"
        });

        Assert.Equal(ServiceResultStatus.Success, created.Status);
        Assert.Equal("tezina_2", created.Value!.Code);
        Assert.Equal("Težina", created.Value.Name);
        Assert.Equal("kg", created.Value.Unit);
        Assert.Equal("tezina_3", second.Value!.Code);
    }

    [Fact]
    public async Task CreateRejectsInvalidStatus()
    {
        await using var db = Database();
        var result = await Service(db, AuthRoles.Admin).CreateParameterAsync(
            new CreateMeasurementParameterRequest { Name = "Test", Status = "archived" });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(db.MeasurementParameters);
    }

    [Fact]
    public async Task UpdateChangesDisplayFieldsButKeepsInternalCode()
    {
        await using var db = Database();
        var parameter = Parameter(1, 1, "weight_kg");
        db.MeasurementParameters.Add(parameter);
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Admin).UpdateParameterAsync(1,
            new UpdateMeasurementParameterRequest
            {
                Name = " Tjelesna težina ", Unit = " kg ", SortOrder = 5, Status = "inactive"
            });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal("weight_kg", parameter.Code);
        Assert.Equal("Tjelesna težina", parameter.Name);
        Assert.Equal("kg", parameter.Unit);
        Assert.Equal(5, parameter.SortOrder);
        Assert.Equal("inactive", parameter.Status);
    }

    [Fact]
    public async Task DeleteDeactivatesOnlyCurrentStudioParameter()
    {
        await using var db = Database();
        db.MeasurementParameters.AddRange(Parameter(1, 1, "local"), Parameter(2, 2, "foreign"));
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Admin);

        var deleted = await service.DeleteParameterAsync(1);
        var foreign = await service.DeleteParameterAsync(2);

        Assert.Equal(ServiceResultStatus.Success, deleted.Status);
        Assert.Equal("inactive", db.MeasurementParameters.Find(1L)!.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task BulkConfigurationUpdatesAddsAndPersistsOrder()
    {
        await using var db = Database();
        db.MeasurementParameters.Add(Parameter(1, 1, "weight_kg"));
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Admin).SaveConfigurationAsync(
            new SaveMeasurementParametersConfigurationRequest
            {
                Items =
                [
                    ConfigurationItem(null, "Opseg struka", "active", 0),
                    ConfigurationItem(1, "Težina", "inactive", 1)
                ]
            });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(["opseg_struka", "weight_kg"], result.Value!.Select(item => item.Code));
        Assert.Equal("inactive", db.MeasurementParameters.Find(1L)!.Status);
        Assert.Contains(db.MeasurementParameters, item => item.Code == "opseg_struka");
    }

    [Fact]
    public async Task BulkConfigurationRejectsDuplicateIdsWithoutPersistingOtherEdits()
    {
        await using var db = Database();
        db.MeasurementParameters.Add(Parameter(1, 1, "weight_kg"));
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Admin).SaveConfigurationAsync(
            new SaveMeasurementParametersConfigurationRequest
            {
                Items =
                [
                    ConfigurationItem(1, "Changed", "inactive", 1),
                    ConfigurationItem(1, "Duplicate", "active", 2)
                ]
            });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        var stored = db.MeasurementParameters.Single();
        Assert.Equal("weight_kg", stored.Name);
        Assert.Equal("active", stored.Status);
    }

    [Fact]
    public async Task BulkConfigurationRejectsParametersFromAnotherStudio()
    {
        await using var db = Database();
        db.MeasurementParameters.Add(Parameter(2, 2, "foreign"));
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Admin).SaveConfigurationAsync(
            new SaveMeasurementParametersConfigurationRequest
            {
                Items = [ConfigurationItem(2, "Foreign", "inactive", 0)]
            });

        Assert.Equal(ServiceResultStatus.NotFound, result.Status);
        Assert.Equal("active", db.MeasurementParameters.Single().Status);
    }

    private static MeasurementParametersService Service(FitnessStudioDbContext db, string role) =>
        new(db, new Context(role));

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static MeasurementParameter Parameter(
        long id, long studioId, string code, string status = "active", int sortOrder = 0) => new()
        {
            Id = id,
            StudioId = studioId,
            Code = code,
            Name = code,
            SortOrder = sortOrder,
            Status = status,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static MeasurementParameterConfigurationItemRequest ConfigurationItem(
        long? id, string name, string status, int sortOrder) => new()
        {
            Id = id, Name = name, SortOrder = sortOrder, Status = status
        };

    private sealed class Context(string role) : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberId => role == AuthRoles.Member ? 1 : null;
        public long? TrainerId => role == AuthRoles.Trainer ? 1 : null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { role };
        public bool IsMemberOnly => role == AuthRoles.Member;
        public bool IsInRole(string requestedRole) => Roles.Contains(requestedRole);
    }
}
