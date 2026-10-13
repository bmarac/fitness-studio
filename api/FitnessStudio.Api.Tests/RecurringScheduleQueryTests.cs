using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.RecurringClassSchedules;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class RecurringScheduleQueryTests
{
    [Fact]
    public async Task GetSchedulesCountsOnlyCurrentlyActiveFixedMembers()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));

        db.Studios.Add(new Studio
        {
            Id = 1,
            Name = "Studio",
            Timezone = timezone.Id,
            Status = "active"
        });
        db.ClassTypes.Add(new ClassType
        {
            Id = 5,
            StudioId = 1,
            Name = "Pilates",
            DifficultyLevel = "all",
            Status = "active"
        });
        db.Trainers.Add(new Trainer
        {
            Id = 8,
            StudioId = 1,
            FirstName = "Ana",
            LastName = "Horvat",
            Email = "ana@example.com",
            Status = "active"
        });
        db.RecurringClassSchedules.Add(new RecurringClassSchedule
        {
            Id = 41,
            StudioId = 1,
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(18, 0),
            DurationMinutes = 60,
            Capacity = 12,
            ValidFrom = today.AddDays(-30),
            Status = "active",
            MemberFixedSchedules =
            [
                Assignment(1, today.AddDays(-7), null, "active"),
                Assignment(2, today, today, "active"),
                Assignment(3, today.AddDays(1), null, "active"),
                Assignment(4, today.AddDays(-7), today.AddDays(-1), "active"),
                Assignment(5, today.AddDays(-7), null, "paused"),
                Assignment(6, today.AddDays(-7), null, "cancelled")
            ]
        });
        await db.SaveChangesAsync();
        var service = new RecurringClassSchedulesService(
            db,
            new CurrentUserContext(),
            null!,
            null!);

        var schedules = await service.GetSchedulesAsync();

        var schedule = Assert.Single(schedules);
        Assert.Equal(2, schedule.ActiveMemberCount);
        Assert.Equal(12, schedule.Capacity);
    }

    [Fact]
    public async Task GetScheduleMembersReturnsOnlyCurrentMembersSortedByName()
    {
        await using var db = CreateDatabase();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = DateOnly.FromDateTime(
            TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timezone));
        db.Studios.Add(new Studio
        {
            Id = 1,
            Name = "Studio",
            Timezone = timezone.Id,
            Status = "active"
        });
        db.ClassTypes.Add(new ClassType
        {
            Id = 5,
            StudioId = 1,
            Name = "Pilates",
            DifficultyLevel = "all",
            Status = "active"
        });
        db.Trainers.Add(new Trainer
        {
            Id = 8,
            StudioId = 1,
            FirstName = "Ana",
            LastName = "Horvat",
            Email = "ana@example.com",
            Status = "active"
        });
        db.Members.AddRange(
            Member(1, "Zoran", "Zec"),
            Member(2, "Ana", "Anic"),
            Member(3, "Buduci", "Clan"));
        db.RecurringClassSchedules.Add(new RecurringClassSchedule
        {
            Id = 41,
            StudioId = 1,
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(18, 0),
            DurationMinutes = 60,
            Capacity = 12,
            ValidFrom = today.AddDays(-30),
            Status = "active",
            MemberFixedSchedules =
            [
                Assignment(1, today.AddDays(-7), null, "active"),
                Assignment(2, today, today, "active"),
                Assignment(3, today.AddDays(1), null, "active")
            ]
        });
        await db.SaveChangesAsync();
        var service = new RecurringClassSchedulesService(
            db,
            new CurrentUserContext(),
            null!,
            null!);

        var result = await service.GetScheduleMembersAsync(41);

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(["Ana Anic", "Zoran Zec"], result.Value!.Select(item => item.MemberName));
    }

    private static MemberFixedSchedule Assignment(
        long id,
        DateOnly startsOn,
        DateOnly? endsOn,
        string status)
        => new()
        {
            Id = id,
            StudioId = 1,
            MemberId = id,
            StartsOn = startsOn,
            EndsOn = endsOn,
            Status = status
        };

    private static Member Member(long id, string firstName, string lastName)
        => new()
        {
            Id = id,
            StudioId = 1,
            FirstName = firstName,
            LastName = lastName,
            Email = $"member{id}@example.com",
            Status = "active"
        };

    private static FitnessStudioDbContext CreateDatabase()
        => new(new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options);

    private sealed class CurrentUserContext : ICurrentUserContext
    {
        public long UserId => 10;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
