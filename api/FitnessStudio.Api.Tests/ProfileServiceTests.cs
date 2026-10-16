using FitnessStudio.Api.Domain.Memberships;
using FitnessStudio.Api.Dtos.MemberFixedSchedules;
using FitnessStudio.Api.Dtos.MemberMemberships;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Dtos.MembershipPlans;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Profile;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ProfileServiceTests
{
    [Fact]
    public async Task BuildsCompleteProfileAndUsageForLinkedUser()
    {
        var fixture = new Fixture
        {
            CurrentUser = { MemberIdValue = 11, TrainerIdValue = 12 },
            Memberships = { Current = Membership() },
            Plans = { Result = ServiceResult<MembershipPlanResponse>.Success(Plan()) },
            Policy =
            {
                Decision = new MembershipBookingDecision(
                    MembershipBookingDecisionStatus.Allowed,
                    new DateOnly(2030, 1, 1),
                    new DateOnly(2030, 1, 31),
                    3,
                    8,
                    "month")
            }
        };
        fixture.FixedSchedules.Items.Add(FixedSchedule());

        var result = await fixture.Service.GetProfileAsync();

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var profile = Assert.IsType<FitnessStudio.Api.Dtos.Profile.ProfileResponse>(result.Value);
        Assert.Equal(["admin", "trainer"], profile.User.Roles);
        Assert.Equal("Stay Fit", profile.Studio.Name);
        Assert.Equal(11, profile.Member!.Id);
        Assert.Equal(12, profile.Trainer!.Id);
        Assert.Equal("Monthly", profile.Membership!.PlanName);
        Assert.Equal(49.90m, profile.Membership.PriceAmount);
        Assert.Equal(3, profile.Usage!.Used);
        Assert.Equal(8, profile.Usage.Allowed);
        Assert.Single(profile.FixedSchedules);
        Assert.Equal(11, fixture.Members.RequestedId);
        Assert.Equal(12, fixture.Trainers.RequestedId);
        Assert.Equal(41, fixture.Plans.RequestedId);
        Assert.Equal(11, fixture.Policy.MemberId);
        Assert.NotNull(fixture.Policy.At);
    }

    [Fact]
    public async Task OmitsOptionalSectionsWhenUserHasNoLinkedRecords()
    {
        var fixture = new Fixture();

        var result = await fixture.Service.GetProfileAsync();

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Null(result.Value!.Member);
        Assert.Null(result.Value.Trainer);
        Assert.Null(result.Value.Membership);
        Assert.Null(result.Value.Usage);
        Assert.Null(fixture.Members.RequestedId);
        Assert.Null(fixture.Trainers.RequestedId);
        Assert.Null(fixture.Plans.RequestedId);
        Assert.Null(fixture.Policy.MemberId);
        Assert.Equal(1, fixture.FixedSchedules.CallCount);
    }

    [Fact]
    public async Task UnlimitedMembershipDoesNotEvaluateUsagePolicy()
    {
        var fixture = new Fixture
        {
            CurrentUser = { MemberIdValue = 11 },
            Memberships = { Current = Membership() },
            Plans =
            {
                Result = ServiceResult<MembershipPlanResponse>.Success(
                    Plan(sessionLimit: null, sessionLimitPeriod: null))
            }
        };

        var result = await fixture.Service.GetProfileAsync();

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.NotNull(result.Value!.Membership);
        Assert.Null(result.Value.Usage);
        Assert.Null(fixture.Policy.MemberId);
    }

    [Fact]
    public async Task StudioFailureIsReturnedWithoutLoadingOtherSections()
    {
        var fixture = new Fixture
        {
            Studios =
            {
                Result = ServiceResult<StudioResponse>.Forbidden(
                    "Studio denied.",
                    "No studio access.")
            },
            CurrentUser = { MemberIdValue = 11, TrainerIdValue = 12 }
        };

        var result = await fixture.Service.GetProfileAsync();

        AssertFailure(result, ServiceResultStatus.Forbidden, "Studio denied.");
        Assert.Null(fixture.Members.RequestedId);
        Assert.Null(fixture.Trainers.RequestedId);
        Assert.Equal(0, fixture.Memberships.CallCount);
        Assert.Equal(0, fixture.FixedSchedules.CallCount);
    }

    [Fact]
    public async Task MemberFailureIsReturnedBeforeTrainerAndMembershipLookup()
    {
        var fixture = new Fixture
        {
            CurrentUser = { MemberIdValue = 11, TrainerIdValue = 12 },
            Members =
            {
                Result = ServiceResult<MemberResponse>.NotFound(
                    "Member missing.",
                    "Member does not exist.")
            }
        };

        var result = await fixture.Service.GetProfileAsync();

        AssertFailure(result, ServiceResultStatus.NotFound, "Member missing.");
        Assert.Equal(11, fixture.Members.RequestedId);
        Assert.Null(fixture.Trainers.RequestedId);
        Assert.Equal(0, fixture.Memberships.CallCount);
    }

    [Fact]
    public async Task TrainerFailureIsReturnedBeforeMembershipLookup()
    {
        var fixture = new Fixture
        {
            CurrentUser = { TrainerIdValue = 12 },
            Trainers =
            {
                Result = ServiceResult<TrainerResponse>.Conflict(
                    "Trainer conflict.",
                    "Trainer is unavailable.")
            }
        };

        var result = await fixture.Service.GetProfileAsync();

        AssertFailure(result, ServiceResultStatus.Conflict, "Trainer conflict.");
        Assert.Equal(12, fixture.Trainers.RequestedId);
        Assert.Equal(0, fixture.Memberships.CallCount);
    }

    [Fact]
    public async Task PlanFailureIsReturnedBeforeUsageAndSchedulesLookup()
    {
        var fixture = new Fixture
        {
            Memberships = { Current = Membership() },
            Plans =
            {
                Result = ServiceResult<MembershipPlanResponse>.NotFound(
                    "Plan missing.",
                    "Membership plan does not exist.")
            }
        };

        var result = await fixture.Service.GetProfileAsync();

        AssertFailure(result, ServiceResultStatus.NotFound, "Plan missing.");
        Assert.Equal(41, fixture.Plans.RequestedId);
        Assert.Null(fixture.Policy.MemberId);
        Assert.Equal(0, fixture.FixedSchedules.CallCount);
    }

    private static void AssertFailure<T>(
        ServiceResult<T> result,
        ServiceResultStatus status,
        string title)
    {
        Assert.Equal(status, result.Status);
        Assert.Null(result.Value);
        Assert.Equal(title, result.Error?.Title);
    }

    private static MemberMembershipResponse Membership() => new(
        31,
        11,
        "Ana Horvat",
        41,
        "Monthly",
        new DateOnly(2030, 1, 1),
        new DateOnly(2030, 1, 31),
        new DateOnly(2030, 1, 1),
        new DateOnly(2030, 2, 1),
        true);

    private static MembershipPlanResponse Plan(
        int? sessionLimit = 8,
        string? sessionLimitPeriod = "month") => new(
        41,
        "Monthly",
        "Monthly membership",
        1,
        sessionLimit,
        sessionLimitPeriod,
        49.90m,
        "EUR",
        "active");

    private static MemberFixedScheduleResponse FixedSchedule() => new(
        51,
        11,
        "Ana Horvat",
        61,
        "Pilates",
        "Filip Šarić",
        1,
        new TimeOnly(18, 0),
        new DateOnly(2030, 1, 1),
        null,
        "active");

    private sealed class Fixture
    {
        public FakeCurrentUser CurrentUser { get; init; } = new();
        public FakeStudiosService Studios { get; init; } = new();
        public FakeMembersService Members { get; init; } = new();
        public FakeTrainersService Trainers { get; init; } = new();
        public FakeMembershipsService Memberships { get; init; } = new();
        public FakePlansService Plans { get; init; } = new();
        public FakeFixedSchedulesService FixedSchedules { get; init; } = new();
        public FakeBookingPolicy Policy { get; init; } = new();

        public ProfileService Service => new(
            CurrentUser,
            Studios,
            Members,
            Trainers,
            Memberships,
            Plans,
            FixedSchedules,
            Policy);
    }

    private sealed class FakeCurrentUser : ICurrentUserContext
    {
        public long UserId => 5;
        public string Email => "user@example.com";
        public long StudioId => 1;
        public long? MemberIdValue { get; set; }
        public long? TrainerIdValue { get; set; }
        public long? MemberId => MemberIdValue;
        public long? TrainerId => TrainerIdValue;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>
        {
            "trainer",
            "admin"
        };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class FakeStudiosService : IStudiosService
    {
        public ServiceResult<StudioResponse> Result { get; set; } =
            ServiceResult<StudioResponse>.Success(
                new StudioResponse(1, "Stay Fit", "Europe/Zagreb", "active"));

        public Task<ServiceResult<StudioResponse>> GetCurrentStudioAsync() =>
            Task.FromResult(Result);

        public Task<ServiceResult> UpdateCurrentStudioAsync(UpdateStudioRequest request) =>
            throw new NotSupportedException();
    }

    private sealed class FakeMembersService : IMembersService
    {
        public long? RequestedId { get; private set; }
        public ServiceResult<MemberResponse> Result { get; set; } =
            ServiceResult<MemberResponse>.Success(new MemberResponse
            {
                Id = 11,
                FirstName = "Ana",
                LastName = "Horvat",
                Email = "ana@example.com",
                Status = "active"
            });

        public Task<ServiceResult<MemberResponse>> GetMemberAsync(long id)
        {
            RequestedId = id;
            return Task.FromResult(Result);
        }

        public Task<List<MemberResponse>> GetMembersAsync() => throw new NotSupportedException();
        public Task<ServiceResult> UpdateMemberAsync(long id, UpdateMemberRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> DeleteMemberAsync(long id) => throw new NotSupportedException();
    }

    private sealed class FakeTrainersService : ITrainersService
    {
        public long? RequestedId { get; private set; }
        public ServiceResult<TrainerResponse> Result { get; set; } =
            ServiceResult<TrainerResponse>.Success(new TrainerResponse
            {
                Id = 12,
                FirstName = "Filip",
                LastName = "Šarić",
                Email = "filip@example.com",
                Status = "active"
            });

        public Task<ServiceResult<TrainerResponse>> GetTrainerAsync(long id)
        {
            RequestedId = id;
            return Task.FromResult(Result);
        }

        public Task<List<TrainerResponse>> GetTrainersAsync() => throw new NotSupportedException();
        public Task<ServiceResult<TrainerResponse>> CreateTrainerAsync(CreateTrainerRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> UpdateTrainerAsync(long id, UpdateTrainerRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> DeleteTrainerAsync(long id) => throw new NotSupportedException();
    }

    private sealed class FakeMembershipsService : IMemberMembershipsService
    {
        public int CallCount { get; private set; }
        public MemberMembershipResponse? Current { get; set; }

        public Task<MemberMembershipResponse?> GetCurrentMemberMembershipAsync()
        {
            CallCount++;
            return Task.FromResult(Current);
        }

        public Task<List<MemberMembershipResponse>> GetMembershipsAsync() => throw new NotSupportedException();
        public Task<ServiceResult<MemberMembershipResponse>> GetMembershipAsync(long id) => throw new NotSupportedException();
        public Task<ServiceResult<MemberMembershipResponse>> CreateMembershipAsync(CreateMemberMembershipRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> UpdateMembershipAsync(long id, UpdateMemberMembershipRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> DeleteMembershipAsync(long id) => throw new NotSupportedException();
        public Task<ServiceResult<SetMembershipBillingResponse>> SetBillingAsync(long id, SetMembershipBillingRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> EndMembershipAsync(long id, EndMembershipRequest request) => throw new NotSupportedException();
    }

    private sealed class FakePlansService : IMembershipPlansService
    {
        public long? RequestedId { get; private set; }
        public ServiceResult<MembershipPlanResponse> Result { get; set; } =
            ServiceResult<MembershipPlanResponse>.Success(Plan());

        public Task<ServiceResult<MembershipPlanResponse>> GetPlanAsync(long id)
        {
            RequestedId = id;
            return Task.FromResult(Result);
        }

        public Task<List<MembershipPlanResponse>> GetPlansAsync() => throw new NotSupportedException();
        public Task<ServiceResult<MembershipPlanResponse>> CreatePlanAsync(CreateMembershipPlanRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> UpdatePlanAsync(long id, UpdateMembershipPlanRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> DeletePlanAsync(long id) => throw new NotSupportedException();
    }

    private sealed class FakeFixedSchedulesService : IMemberFixedSchedulesService
    {
        public int CallCount { get; private set; }
        public List<MemberFixedScheduleResponse> Items { get; } = [];

        public Task<List<MemberFixedScheduleResponse>> GetCurrentMemberSchedulesAsync()
        {
            CallCount++;
            return Task.FromResult(Items);
        }

        public Task<List<MemberFixedScheduleResponse>> GetSchedulesAsync() => throw new NotSupportedException();
        public Task<ServiceResult<MemberFixedScheduleResponse>> GetScheduleAsync(long id) => throw new NotSupportedException();
        public Task<ServiceResult<MemberFixedScheduleResponse>> CreateScheduleAsync(CreateMemberFixedScheduleRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> UpdateScheduleAsync(long id, UpdateMemberFixedScheduleRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> CancelScheduleAsync(long id, CancelMemberFixedScheduleRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> MoveScheduleAsync(long id, MoveMemberFixedScheduleRequest request) => throw new NotSupportedException();
        public Task<ServiceResult> DeleteScheduleAsync(long id) => throw new NotSupportedException();
    }

    private sealed class FakeBookingPolicy : IMembershipBookingPolicy
    {
        public long? MemberId { get; private set; }
        public DateTime? At { get; private set; }
        public MembershipBookingDecision Decision { get; set; } = new(
            MembershipBookingDecisionStatus.Allowed,
            new DateOnly(2030, 1, 1),
            new DateOnly(2030, 1, 31),
            0,
            8,
            "month");

        public Task AcquireMemberLockAsync(long memberId) => throw new NotSupportedException();

        public Task<MembershipBookingDecision> EvaluateAsync(
            long memberId,
            DateTime classSessionStartsAt,
            long? ignoredBookingId = null)
        {
            MemberId = memberId;
            At = classSessionStartsAt;
            return Task.FromResult(Decision);
        }
    }
}
