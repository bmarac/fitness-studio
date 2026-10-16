using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Profiles;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Bookings;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class BookingsServiceLifecycleTests
{
    [Fact]
    public async Task GetBookingsIsStudioScopedAndNewestFirst()
    {
        await using var db = Database();
        var local = SeedSchedule(db);
        var foreign = SeedSchedule(db, studioId: 2, memberId: 21, trainerId: 22, sessionId: 23);
        db.Bookings.AddRange(
            Booking(31, local, bookedAt: DateTime.UtcNow.AddHours(-2)),
            Booking(32, local, bookedAt: DateTime.UtcNow.AddHours(-1)),
            Booking(33, foreign, bookedAt: DateTime.UtcNow));
        await db.SaveChangesAsync();

        var result = await Service(db, new Context(), new Policy()).GetBookingsAsync();

        Assert.Equal([32L, 31L], result.Select(item => item.Id));
    }

    [Fact]
    public async Task MemberReadsOnlyOwnBookingsAndPagedActiveResults()
    {
        await using var db = Database();
        var own = SeedSchedule(db);
        var other = SeedSchedule(db, memberId: 12, sessionId: 24);
        db.Bookings.AddRange(
            Booking(31, own, bookedAt: DateTime.UtcNow.AddHours(-1)),
            Booking(32, other, bookedAt: DateTime.UtcNow));
        await db.SaveChangesAsync();
        var context = new Context
        {
            IsMemberOnlyValue = true,
            MemberIdValue = 11,
            RolesValue = [AuthRoles.Member]
        };
        var service = Service(db, context, new Policy());

        var all = await service.GetBookingsAsync();
        var page = await service.GetMemberBookingsAsync(new MemberBookingsQuery
        {
            Filter = "active",
            Page = 1,
            PageSize = 1
        });

        Assert.Equal(31, Assert.Single(all).Id);
        Assert.Equal(ServiceResultStatus.Success, page.Status);
        Assert.Equal(31, Assert.Single(page.Value!.Items).Id);
        Assert.False(page.Value.HasNextPage);
    }

    [Fact]
    public async Task StaffCannotUseMemberBookingsEndpoint()
    {
        await using var db = Database();

        var result = await Service(db, new Context(), new Policy())
            .GetMemberBookingsAsync(new MemberBookingsQuery());

        Assert.Equal(ServiceResultStatus.Forbidden, result.Status);
    }

    [Fact]
    public async Task ClassSessionBookingsRequireAdminOrAssignedTrainer()
    {
        await using var db = Database();
        var seeded = SeedSchedule(db);
        db.Bookings.Add(Booking(31, seeded));
        await db.SaveChangesAsync();
        var forbidden = new Context
        {
            TrainerIdValue = 99,
            RolesValue = [AuthRoles.Trainer]
        };
        var assigned = new Context
        {
            TrainerIdValue = seeded.Session.TrainerId,
            RolesValue = [AuthRoles.Trainer]
        };

        var denied = await Service(db, forbidden, new Policy())
            .GetBookingsByClassSessionIdAsync(seeded.Session.Id);
        var allowed = await Service(db, assigned, new Policy())
            .GetBookingsByClassSessionIdAsync(seeded.Session.Id);
        var missing = await Service(db, assigned, new Policy())
            .GetBookingsByClassSessionIdAsync(999);

        Assert.Equal(ServiceResultStatus.Forbidden, denied.Status);
        Assert.Equal(31, Assert.Single(allowed.Value!).Id);
        Assert.Equal(ServiceResultStatus.NotFound, missing.Status);
    }

    [Fact]
    public async Task GetBookingHidesForeignAndOtherMemberBookings()
    {
        await using var db = Database();
        var own = SeedSchedule(db);
        var other = SeedSchedule(db, memberId: 12, sessionId: 24);
        var foreign = SeedSchedule(db, studioId: 2, memberId: 21, trainerId: 22, sessionId: 23);
        db.Bookings.AddRange(
            Booking(31, own),
            Booking(32, other),
            Booking(33, foreign));
        await db.SaveChangesAsync();
        var context = new Context
        {
            IsMemberOnlyValue = true,
            MemberIdValue = 11,
            RolesValue = [AuthRoles.Member]
        };
        var service = Service(db, context, new Policy());

        var found = await service.GetBookingAsync(31);
        var anotherMember = await service.GetBookingAsync(32);
        var anotherStudio = await service.GetBookingAsync(33);

        Assert.Equal(ServiceResultStatus.Success, found.Status);
        Assert.Equal(ServiceResultStatus.NotFound, anotherMember.Status);
        Assert.Equal(ServiceResultStatus.NotFound, anotherStudio.Status);
    }

    [Fact]
    public async Task MemberCreatesSelfServiceBookingUsingClaimedMemberId()
    {
        await using var db = Database();
        var seeded = SeedSchedule(db);
        await db.SaveChangesAsync();
        var context = new Context
        {
            IsMemberOnlyValue = true,
            MemberIdValue = seeded.Member.Id,
            RolesValue = [AuthRoles.Member]
        };
        var policy = new Policy();

        var result = await Service(db, context, policy).CreateBookingAsync(
            new CreateBookingRequest
            {
                MemberId = 999,
                ClassSessionId = seeded.Session.Id
            });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var stored = Assert.Single(db.Bookings);
        Assert.Equal(seeded.Member.Id, stored.MemberId);
        Assert.Equal("self_service", stored.BookingSource);
        Assert.Equal(BookingStatuses.Booked, stored.Status);
        Assert.Equal(seeded.Member.Id, policy.LockedMemberId);
        Assert.Equal(seeded.Member.Id, policy.EvaluatedMemberId);
    }

    [Fact]
    public async Task CreateRejectsInactiveMemberBeforeMembershipEvaluation()
    {
        await using var db = Database();
        var seeded = SeedSchedule(db, memberStatus: "paused");
        await db.SaveChangesAsync();
        var policy = new Policy();

        var result = await Service(db, new Context(), policy).CreateBookingAsync(
            new CreateBookingRequest
            {
                MemberId = seeded.Member.Id,
                ClassSessionId = seeded.Session.Id
            });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Member is not active.", result.Error?.Title);
        Assert.Null(policy.EvaluatedMemberId);
    }

    [Theory]
    [InlineData(MembershipBookingDecisionStatus.MissingMembership, "Membership is required.")]
    [InlineData(MembershipBookingDecisionStatus.LimitReached, "Membership session limit reached.")]
    public async Task CreateMapsMembershipPolicyFailures(
        MembershipBookingDecisionStatus decision,
        string title)
    {
        await using var db = Database();
        var seeded = SeedSchedule(db);
        await db.SaveChangesAsync();
        var policy = new Policy
        {
            Decision = new MembershipBookingDecision(decision)
        };

        var result = await Service(db, new Context(), policy).CreateBookingAsync(
            new CreateBookingRequest
            {
                MemberId = seeded.Member.Id,
                ClassSessionId = seeded.Session.Id
            });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal(title, result.Error?.Title);
        Assert.Empty(db.Bookings);
    }

    [Fact]
    public async Task CreateRejectsDuplicateAndFullSession()
    {
        await using var duplicateDb = Database();
        var duplicate = SeedSchedule(duplicateDb);
        duplicateDb.Bookings.Add(Booking(31, duplicate));
        await duplicateDb.SaveChangesAsync();

        var duplicateResult = await Service(duplicateDb, new Context(), new Policy())
            .CreateBookingAsync(new CreateBookingRequest
            {
                MemberId = duplicate.Member.Id,
                ClassSessionId = duplicate.Session.Id
            });

        await using var fullDb = Database();
        var full = SeedSchedule(fullDb, capacity: 1);
        var secondMember = SeedSchedule(fullDb, memberId: 12, sessionId: 24).Member;
        fullDb.Bookings.Add(Booking(31, full));
        await fullDb.SaveChangesAsync();

        var fullResult = await Service(fullDb, new Context(), new Policy())
            .CreateBookingAsync(new CreateBookingRequest
            {
                MemberId = secondMember.Id,
                ClassSessionId = full.Session.Id
            });

        Assert.Equal("Booking already exists.", duplicateResult.Error?.Title);
        Assert.Equal("Class session is full.", fullResult.Error?.Title);
    }

    [Fact]
    public async Task AdminCancelsFutureBookingAndRepeatedCancellationIsIdempotent()
    {
        await using var db = Database();
        var seeded = SeedSchedule(db, startsAt: DateTime.UtcNow.AddDays(2));
        db.Bookings.Add(Booking(31, seeded));
        db.StudioSettings.Add(new StudioSetting
        {
            StudioId = 1,
            Setting = "cancellation_cutoff_hours",
            Value = "24",
            ValueType = "integer",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var context = new Context { RolesValue = [AuthRoles.Admin] };
        var service = Service(db, context, new Policy());

        var first = await service.CancelBookingAsync(31);
        var second = await service.CancelBookingAsync(31);

        Assert.Equal(ServiceResultStatus.Success, first.Status);
        Assert.Equal(ServiceResultStatus.Success, second.Status);
        var stored = db.Bookings.Find(31L)!;
        Assert.Equal(BookingStatuses.Cancelled, stored.Status);
        Assert.NotNull(stored.CancelledAt);
    }

    [Fact]
    public async Task CancellationRejectsUnauthorizedAndElapsedBooking()
    {
        await using var db = Database();
        var future = SeedSchedule(db);
        var past = SeedSchedule(
            db,
            memberId: 12,
            sessionId: 24,
            startsAt: DateTime.UtcNow.AddHours(-2));
        db.Bookings.AddRange(Booking(31, future), Booking(32, past));
        await db.SaveChangesAsync();

        var denied = await Service(db, new Context(), new Policy()).CancelBookingAsync(31);
        var admin = new Context { RolesValue = [AuthRoles.Admin] };
        var elapsed = await Service(db, admin, new Policy()).CancelBookingAsync(32);
        var missing = await Service(db, admin, new Policy()).CancelBookingAsync(999);

        Assert.Equal(ServiceResultStatus.Forbidden, denied.Status);
        Assert.Equal(ServiceResultStatus.Conflict, elapsed.Status);
        Assert.Equal(ServiceResultStatus.NotFound, missing.Status);
    }

    [Fact]
    public async Task AssignedTrainerUpdatesAttendanceAndOtherTrainerIsForbidden()
    {
        await using var db = Database();
        var seeded = SeedSchedule(db);
        db.Bookings.Add(Booking(31, seeded, status: BookingStatuses.Waitlisted));
        await db.SaveChangesAsync();
        var assigned = new Context
        {
            TrainerIdValue = seeded.Trainer.Id,
            RolesValue = [AuthRoles.Trainer]
        };
        var other = new Context
        {
            TrainerIdValue = 999,
            RolesValue = [AuthRoles.Trainer]
        };

        var denied = await Service(db, other, new Policy()).UpdateBookingStatusAsync(
            31,
            new UpdateBookingStatusRequest { Status = "attended" });
        var updated = await Service(db, assigned, new Policy()).UpdateBookingStatusAsync(
            31,
            new UpdateBookingStatusRequest { Status = "ATTENDED" });

        Assert.Equal(ServiceResultStatus.Forbidden, denied.Status);
        Assert.Equal(ServiceResultStatus.Success, updated.Status);
        var stored = db.Bookings.Find(31L)!;
        Assert.Equal(BookingStatuses.Attended, stored.Status);
        Assert.NotNull(stored.AttendedAt);
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(warnings =>
                warnings.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options);

    private static BookingsService Service(
        FitnessStudioDbContext db,
        Context context,
        Policy policy)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(_ => { }, typeof(BookingProfile).Assembly);
        using var provider = services.BuildServiceProvider();
        return new BookingsService(
            db,
            provider.GetRequiredService<IMapper>(),
            context,
            policy);
    }

    private static SeededSchedule SeedSchedule(
        FitnessStudioDbContext db,
        long studioId = 1,
        long memberId = 11,
        long trainerId = 12,
        long sessionId = 21,
        int capacity = 10,
        string memberStatus = "active",
        DateTime? startsAt = null)
    {
        var studio = db.Studios.Local.FirstOrDefault(item => item.Id == studioId)
            ?? new Studio
            {
                Id = studioId,
                Name = $"Studio {studioId}",
                Timezone = "UTC",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        var member = new Member
        {
            Id = memberId,
            StudioId = studioId,
            Studio = studio,
            FirstName = $"Member{memberId}",
            LastName = "Test",
            Email = $"member{memberId}@example.com",
            Status = memberStatus,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var trainer = db.Trainers.Local.FirstOrDefault(item => item.Id == trainerId)
            ?? new Trainer
            {
                Id = trainerId,
                StudioId = studioId,
                Studio = studio,
                FirstName = "Filip",
                LastName = "Šarić",
                Email = $"trainer{trainerId}@example.com",
                Status = "active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        var classTypeId = sessionId + 100;
        var classType = new ClassType
        {
            Id = classTypeId,
            StudioId = studioId,
            Studio = studio,
            Name = "Pilates",
            DefaultDurationMinutes = 60,
            DefaultCapacity = capacity,
            DifficultyLevel = "beginner",
            Status = "active",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        var start = startsAt ?? DateTime.UtcNow.AddDays(1);
        var session = new ClassSession
        {
            Id = sessionId,
            StudioId = studioId,
            Studio = studio,
            ClassTypeId = classType.Id,
            ClassType = classType,
            TrainerId = trainer.Id,
            Trainer = trainer,
            StartsAt = start,
            EndsAt = start.AddHours(1),
            Capacity = capacity,
            Status = ClassSessionStatuses.Scheduled,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        db.AddRange(studio, member, trainer, classType, session);
        return new SeededSchedule(studio, member, trainer, session);
    }

    private static Booking Booking(
        long id,
        SeededSchedule seeded,
        DateTime? bookedAt = null,
        string status = BookingStatuses.Booked) => new()
        {
            Id = id,
            StudioId = seeded.Studio.Id,
            Studio = seeded.Studio,
            MemberId = seeded.Member.Id,
            Member = seeded.Member,
            ClassSessionId = seeded.Session.Id,
            ClassSession = seeded.Session,
            BookingSource = "admin",
            Status = status,
            BookedAt = bookedAt ?? DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

    private sealed record SeededSchedule(
        Studio Studio,
        Member Member,
        Trainer Trainer,
        ClassSession Session);

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberIdValue { get; set; }
        public long? TrainerIdValue { get; set; }
        public long? MemberId => MemberIdValue;
        public long? TrainerId => TrainerIdValue;
        public HashSet<string> RolesValue { get; set; } = [];
        public IReadOnlySet<string> Roles => RolesValue;
        public bool IsMemberOnlyValue { get; set; }
        public bool IsMemberOnly => IsMemberOnlyValue;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class Policy : IMembershipBookingPolicy
    {
        public long? LockedMemberId { get; private set; }
        public long? EvaluatedMemberId { get; private set; }
        public MembershipBookingDecision Decision { get; set; } =
            new(MembershipBookingDecisionStatus.Allowed);

        public Task AcquireMemberLockAsync(long memberId)
        {
            LockedMemberId = memberId;
            return Task.CompletedTask;
        }

        public Task<MembershipBookingDecision> EvaluateAsync(
            long memberId,
            DateTime classSessionStartsAt,
            long? ignoredBookingId = null)
        {
            EvaluatedMemberId = memberId;
            return Task.FromResult(Decision);
        }
    }
}
