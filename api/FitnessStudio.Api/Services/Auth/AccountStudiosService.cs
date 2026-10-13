using System.Text.RegularExpressions;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Auth;

public partial class AccountStudiosService : IAccountStudiosService
{
    private const string JoinCode = "join_code";
    private readonly FitnessStudioDbContext _db;
    private readonly ICurrentUserContext _currentUser;

    public AccountStudiosService(FitnessStudioDbContext db, ICurrentUserContext currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<IReadOnlyCollection<AccountStudioResponse>> GetAsync() =>
        await MembershipQuery()
            .OrderBy(item => item.Studio.Name)
            .Select(item => new AccountStudioResponse(
                item.StudioId,
                item.Studio.Name,
                item.MemberId,
                item.TrainerId,
                item.Roles.Select(role => role.Role).OrderBy(role => role).ToArray()))
            .ToListAsync();

    public async Task<ServiceResult<StudioLookupResponse>> LookupAsync(string code)
    {
        var normalized = NormalizeCode(code);
        if (!JoinCodeRegex().IsMatch(normalized))
            return InvalidCode<StudioLookupResponse>();

        var studio = await FindStudioAsync(normalized);
        if (studio is null)
            return InvalidCode<StudioLookupResponse>();

        var profile = await FindProfileAsync(studio.Id);
        if (profile.Ambiguous)
            return ServiceResult<StudioLookupResponse>.Conflict(
                "Profile conflict.", "Both a member and trainer use this email in the studio.");

        return ServiceResult<StudioLookupResponse>.Success(new StudioLookupResponse(
            studio.Id,
            studio.Name,
            profile.Member is null && profile.Trainer is null,
            profile.Trainer is null ? AuthRoles.Member : AuthRoles.Trainer));
    }

    public async Task<ServiceResult<AccountStudioResponse>> JoinAsync(JoinStudioRequest request)
    {
        var normalized = NormalizeCode(request.Code);
        if (!JoinCodeRegex().IsMatch(normalized))
            return InvalidCode<AccountStudioResponse>();

        var studio = await FindStudioAsync(normalized);
        if (studio is null)
            return InvalidCode<AccountStudioResponse>();

        var existing = await MembershipQuery().FirstOrDefaultAsync(item => item.StudioId == studio.Id);
        if (existing is not null)
            return ServiceResult<AccountStudioResponse>.Success(ToResponse(existing));

        var profile = await FindProfileAsync(studio.Id);
        if (profile.Ambiguous)
            return ServiceResult<AccountStudioResponse>.Conflict(
                "Profile conflict.", "Both a member and trainer use this email in the studio.");

        if (profile.Member is null && profile.Trainer is null
            && (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName)))
            return ServiceResult<AccountStudioResponse>.Conflict(
                "Profile details required.", "First name and last name are required for a new member.");

        await using var transaction = _db.Database.IsRelational()
            ? await _db.Database.BeginTransactionAsync()
            : null;
        var now = DateTime.UtcNow;
        var member = profile.Member;
        if (member is null && profile.Trainer is null)
        {
            member = new Member
            {
                StudioId = studio.Id,
                FirstName = request.FirstName!.Trim(),
                LastName = request.LastName!.Trim(),
                Email = _currentUser.Email,
                Status = AuthStatuses.Active,
                CreatedAt = now,
                UpdatedAt = now
            };
            _db.Members.Add(member);
            await _db.SaveChangesAsync();
        }

        var role = profile.Trainer is null ? AuthRoles.Member : AuthRoles.Trainer;
        var membership = new AppUserStudio
        {
            AppUserId = _currentUser.UserId,
            StudioId = studio.Id,
            MemberId = member?.Id,
            TrainerId = profile.Trainer?.Id,
            Status = AuthStatuses.Active,
            JoinedAt = now,
            UpdatedAt = now
        };
        membership.Roles.Add(new AppUserRole { Role = role, CreatedAt = now });
        _db.AppUserStudios.Add(membership);
        await _db.SaveChangesAsync();

        var adminIds = await _db.AppUserRoles
            .Where(item => item.Role == AuthRoles.Admin
                && item.AppUserStudio.StudioId == studio.Id
                && item.AppUserStudio.Status == AuthStatuses.Active)
            .Select(item => item.AppUserStudio.AppUserId)
            .Distinct()
            .ToListAsync();
        var displayName = member is null
            ? $"{profile.Trainer!.FirstName} {profile.Trainer.LastName}"
            : $"{member.FirstName} {member.LastName}";
        foreach (var adminId in adminIds)
        {
            _db.AppNotifications.Add(new AppNotification
            {
                StudioId = studio.Id,
                AppUserId = adminId,
                NotificationType = "member_joined",
                Title = "Novi korisnik studija",
                Body = $"{displayName} ({_currentUser.Email}) pridružio se studiju.",
                CreatedAt = now
            });
        }
        await _db.SaveChangesAsync();
        if (transaction is not null) await transaction.CommitAsync();
        return ServiceResult<AccountStudioResponse>.Success(new AccountStudioResponse(
            studio.Id,
            studio.Name,
            membership.MemberId,
            membership.TrainerId,
            membership.Roles.Select(item => item.Role).OrderBy(item => item).ToArray()));
    }

    private IQueryable<AppUserStudio> MembershipQuery() => _db.AppUserStudios
        .AsNoTracking()
        .Include(item => item.Studio)
        .Include(item => item.Roles)
        .Where(item => item.AppUserId == _currentUser.UserId && item.Status == AuthStatuses.Active);

    private async Task<Studio?> FindStudioAsync(string code) => await _db.StudioSettings
        .AsNoTracking()
        .Where(item => item.Setting == JoinCode && item.Value.ToUpper() == code)
        .Select(item => item.Studio)
        .FirstOrDefaultAsync(item => item.Status == AuthStatuses.Active);

    private async Task<(Member? Member, Trainer? Trainer, bool Ambiguous)> FindProfileAsync(long studioId)
    {
        var member = await _db.Members.FirstOrDefaultAsync(item =>
            item.StudioId == studioId && item.Email.ToLower() == _currentUser.Email);
        var trainer = await _db.Trainers.FirstOrDefaultAsync(item =>
            item.StudioId == studioId && item.Email.ToLower() == _currentUser.Email);
        return (member, trainer, member is not null && trainer is not null);
    }

    private static AccountStudioResponse ToResponse(AppUserStudio item) => new(
        item.StudioId,
        item.Studio.Name,
        item.MemberId,
        item.TrainerId,
        item.Roles.Select(role => role.Role).OrderBy(role => role).ToArray());

    private static ServiceResult<T> InvalidCode<T>() => ServiceResult<T>.NotFound(
        "Studio not found.", "The studio code is invalid or joining is disabled.");

    private static string NormalizeCode(string code) => code.Trim().ToUpperInvariant();

    [GeneratedRegex("^[A-Z0-9][A-Z0-9_-]{2,31}$")]
    private static partial Regex JoinCodeRegex();
}
