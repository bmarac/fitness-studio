using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMeasurements;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.MemberMeasurements;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MemberMeasurementsServiceTests
{
    [Fact]
    public async Task ReadAccessIsLimitedToStaffOrTheOwningMemberInCurrentStudio()
    {
        await using var db = Database();
        db.Members.AddRange(Member(1, 1), Member(2, 1), Member(3, 2));
        await db.SaveChangesAsync();

        var owner = await Service(db, AuthRoles.Member, memberId: 1).GetMeasurementsAsync(1);
        var other = await Service(db, AuthRoles.Member, memberId: 1).GetMeasurementsAsync(2);
        var trainer = await Service(db, AuthRoles.Trainer).GetMeasurementsAsync(2);
        var foreign = await Service(db, AuthRoles.Admin).GetMeasurementsAsync(3);

        Assert.Equal(ServiceResultStatus.Success, owner.Status);
        Assert.Equal(ServiceResultStatus.Forbidden, other.Status);
        Assert.Equal(ServiceResultStatus.Success, trainer.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task StaffCreatesManualValuesIncludingBmi()
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Trainer);

        var result = await service.CreateMeasurementAsync(1, Request(
            (1, 170m), (3, 23.5m), note: "  baseline  "));
        var latest = await service.GetLatestMeasurementsAsync(1);

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal("baseline", result.Value!.Note);
        Assert.Equal(23.5m, result.Value.Values.Single(value => value.Code == "bmi").Value);
        Assert.Equal(2, latest.Value!.Values.Count);
        Assert.Equal(23.5m, latest.Value.Values.Single(value => value.Code == "bmi").Value);
        Assert.Equal(10, result.Value.RecordedByUserId);
        Assert.Single(db.MemberMeasurements);
    }

    [Fact]
    public async Task HistoryContainsOnlyStoredValuesAndIsNewestFirst()
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Trainer);
        var older = DateTime.UtcNow.AddDays(-2);
        var newer = DateTime.UtcNow.AddDays(-1);
        await service.CreateMeasurementAsync(1, RequestAt(older, (1, 170m)));
        await service.CreateMeasurementAsync(1, RequestAt(newer, (2, 68m)));

        var history = await service.GetMeasurementsAsync(1);
        var measurements = Assert.IsType<List<MemberMeasurementResponse>>(history.Value);

        Assert.Equal([newer, older], measurements.Select(item => item.MeasuredAt));
        Assert.DoesNotContain(measurements[0].Values, value => value.Code == "bmi");
        Assert.DoesNotContain(measurements[1].Values, value => value.Code == "bmi");
    }

    [Fact]
    public async Task MemberCreatesOwnMeasurementButCannotCreateForAnotherMember()
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        db.Members.Add(Member(2, 1));
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Member, 1);

        var own = await service.CreateMeasurementAsync(1, Request((1, 170m)));
        var other = await service.CreateMeasurementAsync(2, Request((1, 171m)));

        Assert.Equal(ServiceResultStatus.Success, own.Status);
        Assert.Equal(10, own.Value!.RecordedByUserId);
        Assert.Equal(ServiceResultStatus.Forbidden, other.Status);
        Assert.Single(db.MemberMeasurements);
    }

    [Fact]
    public async Task CreateRejectsMissingFutureAndDuplicateInput()
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        await db.SaveChangesAsync();
        var service = Service(db, AuthRoles.Admin);

        var missingTime = await service.CreateMeasurementAsync(1,
            new CreateMemberMeasurementRequest { Values = [Value(1, 170m)] });
        var future = await service.CreateMeasurementAsync(1,
            RequestAt(DateTime.UtcNow.AddMinutes(6), (1, 170m)));
        var duplicate = await service.CreateMeasurementAsync(1,
            Request((1, 170m), (1, 171m)));

        Assert.All([missingTime, future, duplicate], item =>
            Assert.Equal(ServiceResultStatus.Conflict, item.Status));
        Assert.Empty(db.MemberMeasurements);
    }

    [Theory]
    [InlineData(4)]
    [InlineData(99)]
    public async Task CreateRejectsInactiveOrUnknownParameters(long parameterId)
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        db.MeasurementParameters.AddRange(
            Parameter(4, "inactive", status: "inactive"));
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Trainer).CreateMeasurementAsync(
            1, Request((parameterId, 10.1234m)));

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Empty(db.MemberMeasurements);
    }

    [Theory]
    [InlineData(42)]
    [InlineData(42.1234)]
    [InlineData(501.5)]
    public async Task CreateAcceptsWholeAndDecimalValuesWithoutParameterRanges(double value)
    {
        await using var db = Database();
        SeedMemberAndParameters(db);
        await db.SaveChangesAsync();

        var result = await Service(db, AuthRoles.Trainer).CreateMeasurementAsync(
            1, Request((1, Convert.ToDecimal(value))));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
    }

    private static MemberMeasurementsService Service(
        FitnessStudioDbContext db, string role, long? memberId = null) =>
        new(db, new Context(role, memberId));

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static void SeedMemberAndParameters(FitnessStudioDbContext db)
    {
        db.Members.Add(Member(1, 1));
        db.MeasurementParameters.AddRange(
            Parameter(1, "height_cm", sort: 1),
            Parameter(2, "weight_kg", sort: 2),
            Parameter(3, "bmi", sort: 3));
    }

    private static Member Member(long id, long studioId) => new()
    {
        Id = id,
        StudioId = studioId,
        FirstName = "Member",
        LastName = id.ToString(),
        Email = $"member{id}@example.com",
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static MeasurementParameter Parameter(
        long id, string code, string status = "active", int sort = 0) => new()
        {
            Id = id,
            StudioId = 1,
            Code = code,
            Name = code,
            Unit = null,
            SortOrder = sort,
            Status = status,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private static CreateMemberMeasurementRequest Request(
        (long Id, decimal Value) first, params (long Id, decimal Value)[] rest) =>
        RequestAt(DateTime.UtcNow.AddMinutes(-1), first, rest);

    private static CreateMemberMeasurementRequest Request(
        (long Id, decimal Value) first, (long Id, decimal Value) second, string note) => new()
        {
            MeasuredAt = DateTime.UtcNow.AddMinutes(-1),
            Note = note,
            Values = [Value(first.Id, first.Value), Value(second.Id, second.Value)]
        };

    private static CreateMemberMeasurementRequest RequestAt(
        DateTime measuredAt, (long Id, decimal Value) first,
        params (long Id, decimal Value)[] rest) => new()
        {
            MeasuredAt = measuredAt,
            Values = [Value(first.Id, first.Value), .. rest.Select(item => Value(item.Id, item.Value))]
        };

    private static CreateMemberMeasurementValueRequest Value(long id, decimal value) =>
        new() { ParameterId = id, Value = value };

    private sealed class Context(string role, long? memberId) : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberId => memberId;
        public long? TrainerId => role == AuthRoles.Trainer ? 1 : null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { role };
        public bool IsMemberOnly => role == AuthRoles.Member;
        public bool IsInRole(string requestedRole) => Roles.Contains(requestedRole);
    }
}
