using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Auth;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace FitnessStudio.Api.Services.Auth;

public class AuthService : IAuthService
{
    private readonly FitnessStudioDbContext _db;
    private readonly JwtOptions _jwt;
    private readonly IPasswordHasher<AppUser> _hasher;

    public AuthService(FitnessStudioDbContext db, IOptions<JwtOptions> jwt, IPasswordHasher<AppUser> hasher)
    {
        _db = db;
        _jwt = jwt.Value;
        _hasher = hasher;
    }

    public async Task<ServiceResult<AccountSessionResponse>> LoginAsync(LoginRequest request)
    {
        var email = NormalizeEmail(request.Email);
        var user = await AccountQuery().FirstOrDefaultAsync(item => item.Email == email);
        if (user is null || user.Status != AuthStatuses.Active)
            return InvalidAccountCredentials();

        var verification = _hasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (verification == PasswordVerificationResult.Failed)
            return InvalidAccountCredentials();
        if (verification == PasswordVerificationResult.SuccessRehashNeeded)
            user.PasswordHash = _hasher.HashPassword(user, request.Password);

        user.LastLoginAt = DateTime.UtcNow;
        user.UpdatedAt = user.LastLoginAt.Value;
        await _db.SaveChangesAsync();
        return ServiceResult<AccountSessionResponse>.Success(CreateAccountSession(user));
    }

    public async Task<ServiceResult<AccountSessionResponse>> RegisterAsync(RegisterRequest request)
    {
        var email = NormalizeEmail(request.Email);
        if (await _db.AppUsers.AnyAsync(item => item.Email == email))
            return ServiceResult<AccountSessionResponse>.Conflict(
                "Account already exists.", "An account with this email already exists.");

        var now = DateTime.UtcNow;
        var user = new AppUser
        {
            Email = email,
            PasswordHash = string.Empty,
            Status = AuthStatuses.Active,
            CreatedAt = now,
            UpdatedAt = now,
            LastLoginAt = now
        };
        user.PasswordHash = _hasher.HashPassword(user, request.Password);
        _db.AppUsers.Add(user);
        await _db.SaveChangesAsync();
        return ServiceResult<AccountSessionResponse>.Success(CreateAccountSession(user));
    }

    public async Task<ServiceResult<LoginResponse>> CreateStudioSessionAsync(long userId, long studioId)
    {
        var membership = await _db.AppUserStudios
            .Include(item => item.AppUser)
            .Include(item => item.Studio)
            .Include(item => item.Roles)
            .FirstOrDefaultAsync(item => item.AppUserId == userId && item.StudioId == studioId);
        if (membership is null
            || membership.Status != AuthStatuses.Active
            || membership.AppUser.Status != AuthStatuses.Active
            || membership.Studio.Status != AuthStatuses.Active)
            return ServiceResult<LoginResponse>.Forbidden(
                "Studio access denied.", "The account is not active in this studio.");

        var expiresAt = DateTime.UtcNow.AddMinutes(_jwt.ExpirationMinutes);
        return ServiceResult<LoginResponse>.Success(new LoginResponse(
            CreateToken(membership.AppUser, expiresAt, membership),
            expiresAt,
            new AuthenticatedUserResponse(
                membership.AppUserId,
                membership.StudioId,
                membership.MemberId,
                membership.TrainerId,
                membership.AppUser.Email,
                membership.Roles.Select(item => item.Role).OrderBy(role => role).ToArray())));
    }

    private IQueryable<AppUser> AccountQuery() => _db.AppUsers
        .Include(item => item.StudioMemberships).ThenInclude(item => item.Studio)
        .Include(item => item.StudioMemberships).ThenInclude(item => item.Roles);

    private AccountSessionResponse CreateAccountSession(AppUser user)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(_jwt.ExpirationMinutes);
        return new AccountSessionResponse(
            CreateToken(user, expiresAt),
            expiresAt,
            new AccountUserResponse(user.Id, user.Email),
            user.StudioMemberships
                .Where(item => item.Status == AuthStatuses.Active && item.Studio.Status == AuthStatuses.Active)
                .OrderBy(item => item.Studio.Name)
                .Select(item => new AccountStudioResponse(
                    item.StudioId,
                    item.Studio.Name,
                    item.MemberId,
                    item.TrainerId,
                    item.Roles.Select(role => role.Role).OrderBy(role => role).ToArray()))
                .ToArray());
    }

    private string CreateToken(AppUser user, DateTime expiresAt, AppUserStudio? membership = null)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email)
        };
        if (membership is not null)
        {
            claims.Add(new Claim(AuthClaimTypes.StudioId, membership.StudioId.ToString()));
            claims.AddRange(membership.Roles.Select(item => new Claim(ClaimTypes.Role, item.Role)));
            if (membership.MemberId.HasValue)
                claims.Add(new Claim(AuthClaimTypes.MemberId, membership.MemberId.Value.ToString()));
            if (membership.TrainerId.HasValue)
                claims.Add(new Claim(AuthClaimTypes.TrainerId, membership.TrainerId.Value.ToString()));
        }

        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwt.SigningKey)),
            SecurityAlgorithms.HmacSha256);
        return new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
            issuer: _jwt.Issuer,
            audience: _jwt.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials));
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    private static ServiceResult<AccountSessionResponse> InvalidAccountCredentials() =>
        ServiceResult<AccountSessionResponse>.Unauthorized(
            "Login failed.", "Email or password is incorrect.");
}
