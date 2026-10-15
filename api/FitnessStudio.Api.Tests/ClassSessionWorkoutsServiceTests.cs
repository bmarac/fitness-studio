using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Profiles;
using FitnessStudio.Api.Services.ClassSessions;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ClassSessionWorkoutsServiceTests
{
    [Fact]
    public async Task TrainerIsScopedByClaimAndResultIsPaged()
    {
        await using var db = Database();
        SeedReferences(db);
        var now = DateTime.UtcNow;
        db.ClassSessions.AddRange(
            Session(1, 1, 7, now.AddHours(1), ClassSessionStatuses.Scheduled),
            Session(2, 1, 7, now.AddHours(2), ClassSessionStatuses.Scheduled),
            Session(3, 1, 7, now.AddHours(3), ClassSessionStatuses.Scheduled),
            Session(4, 1, 8, now.AddHours(1), ClassSessionStatuses.Scheduled),
            Session(5, 2, 7, now.AddHours(1), ClassSessionStatuses.Scheduled));
        await db.SaveChangesAsync();
        var service = Service(db, new Context(AuthRoles.Trainer, trainerId: 7));

        var page = await service.GetWorkoutsAsync(new ClassSessionWorkoutsQuery
        {
            PageSize = 2,
            TrainerId = 8
        });

        Assert.Equal([1L, 2L], page.Items.Select(item => item.Id));
        Assert.True(page.HasNextPage);
        Assert.Equal(1, page.Page);
        Assert.Equal(2, page.PageSize);
    }

    [Fact]
    public async Task AdminCanFilterCompletedWorkoutsByTrainer()
    {
        await using var db = Database();
        SeedReferences(db);
        var now = DateTime.UtcNow;
        db.ClassSessions.AddRange(
            Session(1, 1, 7, now.AddHours(-4), ClassSessionStatuses.Scheduled),
            Session(2, 1, 7, now.AddHours(-2), ClassSessionStatuses.Completed),
            Session(3, 1, 7, now.AddHours(2), ClassSessionStatuses.Scheduled),
            Session(4, 1, 8, now.AddHours(-2), ClassSessionStatuses.Completed));
        await db.SaveChangesAsync();
        var service = Service(db, new Context(AuthRoles.Admin));

        var page = await service.GetWorkoutsAsync(new ClassSessionWorkoutsQuery
        {
            Filter = "completed",
            TrainerId = 7
        });

        Assert.Equal([2L, 1L], page.Items.Select(item => item.Id));
        Assert.False(page.HasNextPage);
    }

    [Theory]
    [InlineData("active", 3)]
    [InlineData("completed", 2)]
    [InlineData("cancelled", 1)]
    [InlineData("all", 3)]
    public void FiltersAndOrdersExpectedWorkouts(string filter, long firstId)
    {
        var now = new DateTime(2026, 10, 15, 12, 0, 0, DateTimeKind.Utc);
        var sessions = new[]
        {
            Session(1, 1, 7, now.AddHours(-2), ClassSessionStatuses.Cancelled),
            Session(2, 1, 7, now.AddHours(-1), ClassSessionStatuses.Scheduled),
            Session(3, 1, 7, now.AddHours(1), ClassSessionStatuses.Scheduled),
            Session(4, 1, 7, now.AddHours(-3), ClassSessionStatuses.Completed)
        }.AsQueryable();

        var result = ClassSessionsService.FilterAndOrderWorkouts(sessions, filter, now).ToList();

        Assert.Equal(firstId, result.First().Id);
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static ClassSessionsService Service(
        FitnessStudioDbContext db,
        ICurrentUserContext context)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(_ => { }, typeof(ClassSessionProfile).Assembly);
        using var provider = services.BuildServiceProvider();
        return new ClassSessionsService(db, provider.GetRequiredService<IMapper>(), context);
    }

    private static void SeedReferences(FitnessStudioDbContext db)
    {
        db.ClassTypes.Add(new ClassType
        {
            Id = 1,
            StudioId = 1,
            Name = "Pilates",
            DifficultyLevel = "all_levels",
            Status = "active"
        });
        db.Trainers.AddRange(
            Trainer(7, 1, "Ana"),
            Trainer(8, 1, "Iva"));
    }

    private static Trainer Trainer(long id, long studioId, string firstName) => new()
    {
        Id = id,
        StudioId = studioId,
        FirstName = firstName,
        LastName = "Trener",
        Email = $"{firstName.ToLowerInvariant()}@example.com",
        Status = "active"
    };

    private static ClassSession Session(
        long id,
        long studioId,
        long trainerId,
        DateTime startsAt,
        string status) => new()
        {
            Id = id,
            StudioId = studioId,
            ClassTypeId = 1,
            TrainerId = trainerId,
            StartsAt = startsAt,
            EndsAt = startsAt.AddHours(1),
            Capacity = 10,
            Status = status
        };

    private sealed class Context(string role, long? trainerId = null) : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => trainerId;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { role };
        public bool IsMemberOnly => false;
        public bool IsInRole(string expectedRole) => Roles.Contains(expectedRole);
    }
}
