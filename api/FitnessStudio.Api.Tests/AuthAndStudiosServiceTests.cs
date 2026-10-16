using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Auth;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class AuthAndStudiosServiceTests
{
    [Fact]
    public async Task AccountStudiosListsOnlyActiveMembershipsForCurrentUserSortedByStudio()
    {
        await using var db = CreateDatabase();
        var user = CreateUser();
        var otherUser = CreateUser(11, "other@example.com");
        var zeta = CreateStudio();
        zeta.Name = "Zeta";
        var alpha = CreateStudio();
        alpha.Id = 2;
        alpha.Name = "Alpha";
        var inactive = CreateStudio();
        inactive.Id = 3;
        inactive.Name = "Hidden";
        var first = Membership(user, zeta, AuthRoles.Trainer);
        first.Roles.Add(new AppUserRole { Role = AuthRoles.Admin, CreatedAt = DateTime.UtcNow });
        var second = Membership(user, alpha, AuthRoles.Member);
        var disabled = Membership(user, inactive, AuthRoles.Member);
        disabled.Status = "inactive";
        var other = Membership(otherUser, inactive, AuthRoles.Admin);
        db.AddRange(user, otherUser, zeta, alpha, inactive, first, second, disabled, other);
        await db.SaveChangesAsync();
        var service = new AccountStudiosService(
            db, new FakeCurrentUserContext(user.Id, user.Email));

        var result = await service.GetAsync();

        Assert.Equal(["Alpha", "Zeta"], result.Select(item => item.StudioName));
        Assert.Equal([AuthRoles.Admin, AuthRoles.Trainer], result.Last().Roles);
    }

    [Theory]
    [InlineData("x")]
    [InlineData("invalid code")]
    [InlineData("missing")]
    public async Task InvalidOrUnknownJoinCodeIsRejectedForLookupAndJoin(string code)
    {
        await using var db = CreateDatabase();
        var service = new AccountStudiosService(
            db, new FakeCurrentUserContext(10, "member@example.com"));

        var lookup = await service.LookupAsync(code);
        var join = await service.JoinAsync(new JoinStudioRequest { Code = code });

        Assert.Equal(ServiceResultStatus.NotFound, lookup.Status);
        Assert.Equal(ServiceResultStatus.NotFound, join.Status);
    }

    [Fact]
    public async Task AmbiguousProfileIsRejectedForLookupAndJoin()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var user = CreateUser();
        db.AddRange(studio, user, new StudioSetting
        {
            Studio = studio,
            Setting = "join_code",
            Value = "STAYFIT",
            ValueType = "string"
        }, new Member
        {
            Studio = studio,
            FirstName = "Ana",
            LastName = "Member",
            Email = user.Email,
            Status = AuthStatuses.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        }, new Trainer
        {
            Studio = studio,
            FirstName = "Ana",
            LastName = "Trainer",
            Email = user.Email,
            Status = AuthStatuses.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var service = new AccountStudiosService(
            db, new FakeCurrentUserContext(user.Id, user.Email));

        var lookup = await service.LookupAsync("stayfit");
        var join = await service.JoinAsync(new JoinStudioRequest { Code = "stayfit" });

        Assert.Equal(ServiceResultStatus.Conflict, lookup.Status);
        Assert.Equal("Profile conflict.", lookup.Error?.Title);
        Assert.Equal(ServiceResultStatus.Conflict, join.Status);
    }

    [Fact]
    public async Task NewMemberMustProvideBothNames()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var user = CreateUser();
        db.AddRange(studio, user, new StudioSetting
        {
            Studio = studio,
            Setting = "join_code",
            Value = "STAYFIT",
            ValueType = "string"
        });
        await db.SaveChangesAsync();
        var service = new AccountStudiosService(
            db, new FakeCurrentUserContext(user.Id, user.Email));

        var result = await service.JoinAsync(new JoinStudioRequest
        {
            Code = "stayfit",
            FirstName = "Ana"
        });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Profile details required.", result.Error?.Title);
        Assert.Empty(db.AppUserStudios);
    }

    [Fact]
    public async Task RegisterAndLoginReturnAnAccountSessionWithoutStudioClaims()
    {
        await using var db = CreateDatabase();
        var service = CreateAuthService(db);

        var registered = await service.RegisterAsync(new RegisterRequest
        {
            Email = " MEMBER@EXAMPLE.COM ",
            Password = "Password123!"
        });
        var loggedIn = await service.LoginAsync(new LoginRequest
        {
            Email = "member@example.com",
            Password = "Password123!"
        });

        Assert.Equal(ServiceResultStatus.Success, registered.Status);
        Assert.Equal(ServiceResultStatus.Success, loggedIn.Status);
        Assert.Empty(loggedIn.Value!.Studios);
        Assert.DoesNotContain("studio_id", ReadClaims(loggedIn.Value.AccessToken).Keys);
        Assert.Equal("member@example.com", loggedIn.Value.User.Email);
    }

    [Fact]
    public async Task LoginReturnsMembershipAndSelectCreatesScopedSession()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var user = CreateUser();
        var membership = new AppUserStudio
        {
            AppUser = user,
            Studio = studio,
            Status = AuthStatuses.Active,
            JoinedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        membership.Roles.Add(new AppUserRole { Role = AuthRoles.Admin, CreatedAt = DateTime.UtcNow });
        db.AddRange(studio, user, membership);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var login = await service.LoginAsync(new LoginRequest
        {
            Email = user.Email,
            Password = "Password123!"
        });
        var selected = await service.CreateStudioSessionAsync(user.Id, studio.Id);

        Assert.Single(login.Value!.Studios);
        Assert.Equal(ServiceResultStatus.Success, selected.Status);
        Assert.Equal(studio.Id, selected.Value!.User.StudioId);
        Assert.Contains(AuthRoles.Admin, selected.Value.User.Roles);
        Assert.Equal(studio.Id.ToString(), ReadClaims(selected.Value.AccessToken)["studio_id"]);
    }

    [Fact]
    public async Task LookupAndJoinCreateMemberMembershipAndAdminNotification()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var joiningUser = CreateUser(10, "new@example.com");
        var admin = CreateUser(11, "admin@example.com");
        var adminMembership = new AppUserStudio
        {
            AppUser = admin,
            Studio = studio,
            Status = AuthStatuses.Active,
            JoinedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        adminMembership.Roles.Add(new AppUserRole { Role = AuthRoles.Admin, CreatedAt = DateTime.UtcNow });
        db.AddRange(studio, joiningUser, admin, adminMembership, new StudioSetting
        {
            Studio = studio,
            Setting = "join_code",
            Value = "STAYFIT",
            ValueType = "string"
        });
        await db.SaveChangesAsync();
        var service = new AccountStudiosService(db, new FakeCurrentUserContext(joiningUser.Id, joiningUser.Email));

        var lookup = await service.LookupAsync(" stayfit ");
        var joined = await service.JoinAsync(new JoinStudioRequest
        {
            Code = "stayfit",
            FirstName = "Nova",
            LastName = "Članica"
        });
        var repeated = await service.JoinAsync(new JoinStudioRequest { Code = "STAYFIT" });

        Assert.True(lookup.Value!.RequiresProfileDetails);
        Assert.Equal(ServiceResultStatus.Success, joined.Status);
        Assert.Equal(AuthRoles.Member, joined.Value!.Roles.Single());
        Assert.Single(db.Members.Where(item => item.Email == joiningUser.Email));
        Assert.Single(db.AppUserStudios.Where(item => item.AppUserId == joiningUser.Id));
        Assert.Single(db.AppNotifications.Where(item => item.NotificationType == "member_joined"));
        Assert.Equal(joined.Value.StudioId, repeated.Value!.StudioId);
    }

    [Fact]
    public async Task JoinAttachesPrecreatedTrainerAndDeletedCodeDisablesLookup()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var user = CreateUser(10, "coach@example.com");
        var setting = new StudioSetting
        {
            Studio = studio,
            Setting = "join_code",
            Value = "COACH",
            ValueType = "string"
        };
        var trainer = new Trainer
        {
            Studio = studio,
            FirstName = "Tina",
            LastName = "Trener",
            Email = user.Email,
            Status = AuthStatuses.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        db.AddRange(studio, user, setting, trainer);
        await db.SaveChangesAsync();
        var service = new AccountStudiosService(db, new FakeCurrentUserContext(user.Id, user.Email));

        var joined = await service.JoinAsync(new JoinStudioRequest { Code = "coach" });
        db.StudioSettings.Remove(setting);
        await db.SaveChangesAsync();
        var disabled = await service.LookupAsync("coach");

        Assert.Equal(trainer.Id, joined.Value!.TrainerId);
        Assert.Contains(AuthRoles.Trainer, joined.Value.Roles);
        Assert.Equal(ServiceResultStatus.NotFound, disabled.Status);
    }

    [Fact]
    public async Task RolesAreIsolatedBetweenStudiosForTheSameGlobalAccount()
    {
        await using var db = CreateDatabase();
        var first = CreateStudio();
        var second = CreateStudio();
        second.Id = 2;
        second.Name = "Second Studio";
        var user = CreateUser();
        var memberMembership = Membership(user, first, AuthRoles.Member);
        var adminMembership = Membership(user, second, AuthRoles.Admin);
        db.AddRange(first, second, user, memberMembership, adminMembership);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);

        var account = await service.LoginAsync(new LoginRequest
        {
            Email = user.Email,
            Password = "Password123!"
        });
        var memberSession = await service.CreateStudioSessionAsync(user.Id, first.Id);
        var adminSession = await service.CreateStudioSessionAsync(user.Id, second.Id);

        Assert.Equal(2, account.Value!.Studios.Count);
        Assert.Equal([AuthRoles.Member], memberSession.Value!.User.Roles);
        Assert.Equal([AuthRoles.Admin], adminSession.Value!.User.Roles);
    }

    [Fact]
    public async Task LoginCreatesHashedDeviceSessionAndRefreshRotatesToken()
    {
        await using var db = CreateDatabase();
        var clock = new TestTimeProvider(new DateTimeOffset(2026, 10, 16, 10, 0, 0, TimeSpan.Zero));
        var user = CreateUser();
        db.Add(user);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db, clock);

        var login = await service.LoginAsync(new LoginRequest
        {
            Email = user.Email,
            Password = "Password123!"
        });
        var firstToken = login.Value!.RefreshToken!;
        var stored = Assert.Single(db.AppUserRefreshSessions);

        Assert.DoesNotContain(firstToken, stored.CurrentTokenHash);
        Assert.Equal(64, stored.CurrentTokenHash.Length);
        Assert.Equal(clock.GetUtcNow().UtcDateTime.AddDays(30), login.Value.RefreshTokenExpiresAt);

        var refreshed = await service.RefreshAsync(firstToken);

        Assert.Equal(ServiceResultStatus.Success, refreshed.Status);
        Assert.NotEqual(firstToken, refreshed.Value!.RefreshToken);
        Assert.NotNull(stored.PreviousTokenHash);
        Assert.Equal(clock.GetUtcNow().UtcDateTime.AddSeconds(30), stored.PreviousTokenValidUntil);
    }

    [Fact]
    public async Task ReusingOldRefreshTokenAfterGraceRevokesOnlyThatDevice()
    {
        await using var db = CreateDatabase();
        var clock = new TestTimeProvider(new DateTimeOffset(2026, 10, 16, 10, 0, 0, TimeSpan.Zero));
        var user = CreateUser();
        db.Add(user);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db, clock);
        var first = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        var second = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        var firstToken = first.Value!.RefreshToken!;
        var secondToken = second.Value!.RefreshToken!;
        await service.RefreshAsync(firstToken);
        clock.Advance(TimeSpan.FromSeconds(31));

        var replay = await service.RefreshAsync(firstToken);
        var otherDevice = await service.RefreshAsync(secondToken);

        Assert.Equal(ServiceResultStatus.Unauthorized, replay.Status);
        Assert.Equal(ServiceResultStatus.Success, otherDevice.Status);
        Assert.Single(db.AppUserRefreshSessions.Where(item => item.RevokedAt != null));
    }

    [Fact]
    public async Task LogoutRevokesOnlyPresentedRefreshSession()
    {
        await using var db = CreateDatabase();
        var user = CreateUser();
        db.Add(user);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);
        var first = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        var second = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });

        await service.LogoutAsync(first.Value!.RefreshToken!);

        Assert.Equal(ServiceResultStatus.Unauthorized,
            (await service.RefreshAsync(first.Value.RefreshToken!)).Status);
        Assert.Equal(ServiceResultStatus.Success,
            (await service.RefreshAsync(second.Value!.RefreshToken!)).Status);
    }

    [Fact]
    public async Task ExpiredOrInactiveRefreshSessionIsRejected()
    {
        await using var db = CreateDatabase();
        var clock = new TestTimeProvider(new DateTimeOffset(2026, 10, 16, 10, 0, 0, TimeSpan.Zero));
        var user = CreateUser();
        db.Add(user);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db, clock);
        var login = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        clock.Advance(TimeSpan.FromDays(31));

        Assert.Equal(ServiceResultStatus.Unauthorized,
            (await service.RefreshAsync(login.Value!.RefreshToken!)).Status);

        var activeLogin = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        user.Status = "blocked";
        await db.SaveChangesAsync();
        Assert.Equal(ServiceResultStatus.Unauthorized,
            (await service.RefreshAsync(activeLogin.Value!.RefreshToken!)).Status);
    }

    [Fact]
    public async Task RefreshNeverExtendsPastAbsoluteExpiry()
    {
        await using var db = CreateDatabase();
        var clock = new TestTimeProvider(new DateTimeOffset(2026, 10, 16, 10, 0, 0, TimeSpan.Zero));
        var user = CreateUser();
        db.Add(user);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db, clock);
        var login = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        var stored = Assert.Single(db.AppUserRefreshSessions);
        stored.AbsoluteExpiresAt = clock.GetUtcNow().UtcDateTime.AddDays(5);

        var refreshed = await service.RefreshAsync(login.Value!.RefreshToken!);

        Assert.Equal(stored.AbsoluteExpiresAt, refreshed.Value!.RefreshTokenExpiresAt);
        clock.Advance(TimeSpan.FromDays(5));
        Assert.Equal(ServiceResultStatus.Unauthorized,
            (await service.RefreshAsync(refreshed.Value.RefreshToken!)).Status);
    }

    [Fact]
    public async Task RefreshDropsInactiveMembershipAndStudioSelectionIsForbidden()
    {
        await using var db = CreateDatabase();
        var studio = CreateStudio();
        var user = CreateUser();
        var membership = Membership(user, studio, AuthRoles.Member);
        db.AddRange(studio, user, membership);
        await db.SaveChangesAsync();
        var service = CreateAuthService(db);
        var login = await service.LoginAsync(new LoginRequest { Email = user.Email, Password = "Password123!" });
        membership.Status = "inactive";
        await db.SaveChangesAsync();

        var refreshed = await service.RefreshAsync(login.Value!.RefreshToken!);
        var selected = await service.CreateStudioSessionAsync(user.Id, studio.Id);

        Assert.Empty(refreshed.Value!.Studios);
        Assert.Equal(ServiceResultStatus.Forbidden, selected.Status);
    }

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static AuthService CreateAuthService(
        FitnessStudioDbContext db,
        TimeProvider? timeProvider = null) => new(
        db,
        Options.Create(new JwtOptions
        {
            Issuer = "tests",
            Audience = "tests",
            SigningKey = "fitness-studio-tests-signing-key-at-least-32-bytes",
            AccessTokenExpirationMinutes = 30
        }),
        new PasswordHasher<AppUser>(),
        timeProvider);

    private sealed class TestTimeProvider(DateTimeOffset utcNow) : TimeProvider
    {
        private DateTimeOffset _utcNow = utcNow;

        public override DateTimeOffset GetUtcNow() => _utcNow;

        public void Advance(TimeSpan duration) => _utcNow += duration;
    }

    private static AppUser CreateUser(long id = 10, string email = "member@example.com")
    {
        var user = new AppUser
        {
            Id = id,
            Email = email,
            PasswordHash = string.Empty,
            Status = AuthStatuses.Active,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        user.PasswordHash = new PasswordHasher<AppUser>().HashPassword(user, "Password123!");
        return user;
    }

    private static Studio CreateStudio() => new()
    {
        Id = 1,
        Name = "Stay Fit",
        Timezone = "Europe/Zagreb",
        Status = AuthStatuses.Active,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static AppUserStudio Membership(AppUser user, Studio studio, string role)
    {
        var membership = new AppUserStudio
        {
            AppUser = user,
            Studio = studio,
            Status = AuthStatuses.Active,
            JoinedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        membership.Roles.Add(new AppUserRole { Role = role, CreatedAt = DateTime.UtcNow });
        return membership;
    }

    private static Dictionary<string, string> ReadClaims(string token) =>
        new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler().ReadJwtToken(token).Claims
            .ToDictionary(claim => claim.Type, claim => claim.Value);

    private sealed class FakeCurrentUserContext(long userId, string email) : ICurrentUserContext
    {
        public long UserId => userId;
        public string Email => email;
        public long StudioId => throw new InvalidOperationException();
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>();
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => false;
    }
}
