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
    public async Task CreateNormalizesDefinitionAndRejectsDuplicateInCurrentStudio()
    {
        await using var db = Database();
        db.MeasurementParameters.Add(Parameter(1, 2, "weight_kg"));
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Admin);

        var created = await service.CreateParameterAsync(new CreateMeasurementParameterRequest
        {
            Code = " WEIGHT_KG ",
            Name = " Weight ",
            Unit = " kg ",
            ValueType = " DECIMAL ",
            Source = " MANUAL ",
            Status = " ACTIVE ",
            DecimalPlaces = 1
        });
        var duplicate = await service.CreateParameterAsync(new CreateMeasurementParameterRequest
        {
            Code = "weight_kg",
            Name = "Other",
            ValueType = "decimal",
            Source = "manual",
            Status = "active",
            DecimalPlaces = 1
        });

        Assert.Equal(ServiceResultStatus.Success, created.Status);
        Assert.Equal("weight_kg", created.Value!.Code);
        Assert.Equal("Weight", created.Value.Name);
        Assert.Equal("kg", created.Value.Unit);
        Assert.Equal(ServiceResultStatus.Conflict, duplicate.Status);
    }

    [Theory]
    [InlineData("text", "manual", null, 0, 10, 0, "active")]
    [InlineData("decimal", "imported", null, 0, 10, 1, "active")]
    [InlineData("decimal", "manual", "bmi", 0, 10, 1, "active")]
    [InlineData("decimal", "calculated", null, 0, 10, 1, "active")]
    [InlineData("decimal", "calculated", "unknown", 0, 10, 1, "active")]
    [InlineData("decimal", "manual", null, 10, 0, 1, "active")]
    [InlineData("integer", "manual", null, 0, 10, 1, "active")]
    [InlineData("decimal", "manual", null, 0, 10, 1, "archived")]
    public async Task CreateRejectsInvalidDefinitions(
        string valueType, string source, string? calculationType,
        int min, int max, short decimalPlaces, string status)
    {
        await using var db = Database();
        var result = await Service(db, AuthRoles.Admin).CreateParameterAsync(
            new CreateMeasurementParameterRequest
            {
                Code = "test",
                Name = "Test",
                ValueType = valueType,
                Source = source,
                CalculationType = calculationType,
                MinValue = min,
                MaxValue = max,
                DecimalPlaces = decimalPlaces,
                Status = status
            });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(db.MeasurementParameters);
    }

    [Fact]
    public async Task UpdateCannotChangeRecordedDefinitionButCanChangeDisplayFields()
    {
        await using var db = Database();
        var parameter = Parameter(1, 1, "weight");
        db.MeasurementParameters.Add(parameter);
        db.MemberMeasurementValues.Add(new MemberMeasurementValue
        {
            Id = 1,
            MeasurementId = 1,
            ParameterId = 1,
            NumericValue = 70,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Admin);

        var changedDefinition = await service.UpdateParameterAsync(1,
            Update("Weight", "integer", "manual", null));
        var changedDisplay = await service.UpdateParameterAsync(1,
            Update(" Body weight ", "decimal", "manual", null, " kg ", 5));

        Assert.Equal(ServiceResultStatus.Conflict, changedDefinition.Status);
        Assert.Equal(ServiceResultStatus.Success, changedDisplay.Status);
        Assert.Equal("Body weight", parameter.Name);
        Assert.Equal("kg", parameter.Unit);
        Assert.Equal(5, parameter.SortOrder);
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
            ValueType = "decimal",
            Source = "manual",
            DecimalPlaces = 1,
            SortOrder = sortOrder,
            Status = status,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static UpdateMeasurementParameterRequest Update(
        string name, string valueType, string source, string? calculationType,
        string? unit = null, int sortOrder = 0) => new()
        {
            Name = name,
            Unit = unit,
            ValueType = valueType,
            Source = source,
            CalculationType = calculationType,
            DecimalPlaces = valueType == "integer" ? (short)0 : (short)1,
            SortOrder = sortOrder,
            Status = "active"
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
