using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.RecurringClassSchedules;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.RecurringClassSchedules;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class RecurringScheduleUpdateTests
{
    [Fact]
    public async Task UpdateSplitsScheduleAndMovesSessionsBookingsAndAssignments()
    {
        await using var db = CreateDatabase();
        var timeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = StudioToday(timeZone);
        var effectiveFrom = today.AddDays(2);
        SeedReferenceData(db, timeZone);
        var schedule = Schedule(today.AddDays(-30));
        var firstSession = Session(101, schedule, Utc(effectiveFrom.AddDays(1), new TimeOnly(18, 0), timeZone));
        var secondSession = Session(102, schedule, Utc(effectiveFrom.AddDays(8), new TimeOnly(18, 0), timeZone));
        firstSession.Bookings.Add(Booking(201, 1, BookingStatuses.Booked));
        firstSession.Bookings.Add(Booking(202, 2, BookingStatuses.Waitlisted));
        schedule.MemberFixedSchedules.Add(Assignment(301, 1, today.AddDays(-10)));
        schedule.MemberFixedSchedules.Add(Assignment(302, 2, effectiveFrom.AddDays(7)));
        db.Add(schedule);
        await db.SaveChangesAsync();
        var service = Service(db);

        var result = await service.UpdateScheduleAsync(schedule.Id, new UpdateRecurringClassScheduleRequest
        {
            TrainerId = 9,
            DayOfWeek = 4,
            StartsAtTime = new TimeOnly(19, 0),
            Capacity = 2,
            EffectiveFrom = effectiveFrom
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var versions = await db.RecurringClassSchedules.OrderBy(item => item.ValidFrom).ToListAsync();
        Assert.Equal(2, versions.Count);
        Assert.Equal(effectiveFrom.AddDays(-1), versions[0].ValidUntil);
        var replacement = versions[1];
        Assert.Equal(effectiveFrom, replacement.ValidFrom);
        Assert.Equal(9, replacement.TrainerId);
        Assert.Equal(4, replacement.DayOfWeek);
        Assert.Equal(new TimeOnly(19, 0), replacement.StartsAtTime);

        var sessions = await db.ClassSessions
            .Include(item => item.Bookings)
            .OrderBy(item => item.StartsAt)
            .ToListAsync();
        Assert.Equal([101L, 102L], sessions.Select(item => item.Id));
        Assert.All(sessions, item =>
        {
            Assert.Equal(replacement.Id, item.RecurringScheduleId);
            Assert.Equal(9, item.TrainerId);
            Assert.Equal(2, item.Capacity);
            Assert.Equal(new TimeOnly(19, 0), TimeOnly.FromDateTime(
                TimeZoneInfo.ConvertTimeFromUtc(item.StartsAt, timeZone)));
        });
        Assert.All(firstSession.Bookings, item => Assert.Equal(BookingStatuses.Booked, item.Status));

        var assignments = await db.MemberFixedSchedules.OrderBy(item => item.Id).ToListAsync();
        Assert.Equal(3, assignments.Count);
        Assert.Equal(effectiveFrom.AddDays(-1), assignments.Single(item => item.Id == 301).EndsOn);
        Assert.Contains(assignments, item =>
            item.MemberId == 1
            && item.RecurringScheduleId == replacement.Id
            && item.StartsOn == effectiveFrom);
        Assert.Equal(
            replacement.Id,
            assignments.Single(item => item.Id == 302).RecurringScheduleId);
    }

    [Fact]
    public async Task UpdateRejectsCapacityBelowReservationsWithoutChangingSchedule()
    {
        await using var db = CreateDatabase();
        var timeZone = TimeZoneInfo.FindSystemTimeZoneById("Europe/Zagreb");
        var today = StudioToday(timeZone);
        SeedReferenceData(db, timeZone);
        var schedule = Schedule(today.AddDays(-30));
        var session = Session(101, schedule, Utc(today.AddDays(3), new TimeOnly(18, 0), timeZone));
        session.Bookings.Add(Booking(201, 1, BookingStatuses.Booked));
        session.Bookings.Add(Booking(202, 2, BookingStatuses.Waitlisted));
        db.Add(schedule);
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateScheduleAsync(schedule.Id, new UpdateRecurringClassScheduleRequest
        {
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(19, 0),
            Capacity = 1,
            EffectiveFrom = today
        });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Single(await db.RecurringClassSchedules.ToListAsync());
        Assert.Equal(8, schedule.Capacity);
        Assert.Equal(new TimeOnly(18, 0), schedule.StartsAtTime);
        Assert.Equal(BookingStatuses.Waitlisted, session.Bookings.Single(item => item.Id == 202).Status);
    }

    private static RecurringClassSchedulesService Service(FitnessStudioDbContext db)
        => new(db, new CurrentUserContext(), null!, null!);

    private static FitnessStudioDbContext CreateDatabase()
        => new(new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings => warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options);

    private static void SeedReferenceData(FitnessStudioDbContext db, TimeZoneInfo timeZone)
    {
        db.AddRange(
            new Studio { Id = 1, Name = "Studio", Timezone = timeZone.Id, Status = "active" },
            new ClassType
            {
                Id = 5,
                StudioId = 1,
                Name = "Pilates",
                DifficultyLevel = "all",
                Status = "active"
            },
            Trainer(8, "Ana"),
            Trainer(9, "Iva"),
            Member(1),
            Member(2));
    }

    private static RecurringClassSchedule Schedule(DateOnly validFrom)
        => new()
        {
            Id = 41,
            StudioId = 1,
            ClassTypeId = 5,
            TrainerId = 8,
            DayOfWeek = 1,
            StartsAtTime = new TimeOnly(18, 0),
            DurationMinutes = 60,
            Capacity = 8,
            ValidFrom = validFrom,
            Status = "active"
        };

    private static ClassSession Session(long id, RecurringClassSchedule schedule, DateTime startsAt)
    {
        var session = new ClassSession
        {
            Id = id,
            StudioId = 1,
            ClassTypeId = 5,
            TrainerId = 8,
            StartsAt = startsAt,
            EndsAt = startsAt.AddMinutes(60),
            Capacity = 8,
            Status = ClassSessionStatuses.Scheduled
        };
        schedule.ClassSessions.Add(session);
        return session;
    }

    private static Booking Booking(long id, long memberId, string status)
        => new()
        {
            Id = id,
            StudioId = 1,
            MemberId = memberId,
            Status = status,
            BookingSource = "fixed_schedule"
        };

    private static MemberFixedSchedule Assignment(long id, long memberId, DateOnly startsOn)
        => new()
        {
            Id = id,
            StudioId = 1,
            MemberId = memberId,
            StartsOn = startsOn,
            Status = "active"
        };

    private static Trainer Trainer(long id, string firstName)
        => new()
        {
            Id = id,
            StudioId = 1,
            FirstName = firstName,
            LastName = "Trener",
            Email = $"trainer{id}@example.com",
            Status = "active"
        };

    private static Member Member(long id)
        => new()
        {
            Id = id,
            StudioId = 1,
            FirstName = $"Clan{id}",
            LastName = "Test",
            Email = $"member{id}@example.com",
            Status = "active"
        };

    private static DateOnly StudioToday(TimeZoneInfo timeZone)
        => DateOnly.FromDateTime(TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, timeZone));

    private static DateTime Utc(DateOnly date, TimeOnly time, TimeZoneInfo timeZone)
        => TimeZoneInfo.ConvertTimeToUtc(date.ToDateTime(time), timeZone);

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
