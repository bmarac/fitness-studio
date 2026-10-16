using System.IdentityModel.Tokens.Jwt;
using System.Security.Cryptography;
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
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace FitnessStudio.Api.Services.Auth;

public class AuthService : IAuthService
{
    private readonly FitnessStudioDbContext _db;
    private readonly JwtOptions _jwt;
    private readonly IPasswordHasher<AppUser> _hasher;
    private readonly TimeProvider _timeProvider;

    public AuthService(
        FitnessStudioDbContext db,
        IOptions<JwtOptions> jwt,
        IPasswordHasher<AppUser> hasher,
        TimeProvider? timeProvider = null)
    {
        _db = db;
        _jwt = jwt.Value;
        _hasher = hasher;
        _timeProvider = timeProvider ?? TimeProvider.System;
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

        user.LastLoginAt = UtcNow;
        user.UpdatedAt = user.LastLoginAt.Value;
        await _db.SaveChangesAsync();
        return ServiceResult<AccountSessionResponse>.Success(
            CreateAccountSession(user, await CreateRefreshSessionAsync(user)));
    }

    public async Task<ServiceResult<AccountSessionResponse>> RegisterAsync(RegisterRequest request)
    {
        var email = NormalizeEmail(request.Email);
        if (await _db.AppUsers.AnyAsync(item => item.Email == email))
            return ServiceResult<AccountSessionResponse>.Conflict(
                "Account already exists.", "An account with this email already exists.");

        var now = UtcNow;
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
        return ServiceResult<AccountSessionResponse>.Success(
            CreateAccountSession(user, await CreateRefreshSessionAsync(user)));
    }

    public async Task<ServiceResult<AccountSessionResponse>> RefreshAsync(string refreshToken)
    {
        if (!TryParseRefreshToken(refreshToken, out var sessionId, out var secret))
            return InvalidRefreshToken();

        IDbContextTransaction? transaction = null;
        try
        {
            AppUserRefreshSession? session;
            if (_db.Database.IsRelational())
            {
                transaction = await _db.Database.BeginTransactionAsync();
                session = await _db.AppUserRefreshSessions
                    .FromSqlInterpolated($"SELECT * FROM app_user_refresh_sessions WHERE id = {sessionId} FOR UPDATE")
                    .SingleOrDefaultAsync();
            }
            else
            {
                session = await _db.AppUserRefreshSessions.SingleOrDefaultAsync(item => item.Id == sessionId);
            }

            if (session is null)
                return InvalidRefreshToken();

            var now = UtcNow;
            var suppliedHash = HashSecret(secret);
            var currentMatches = HashesMatch(session.CurrentTokenHash, suppliedHash);
            var previousMatches = session.PreviousTokenHash is not null
                && session.PreviousTokenValidUntil > now
                && HashesMatch(session.PreviousTokenHash, suppliedHash);
            if (session.RevokedAt is not null
                || session.IdleExpiresAt <= now
                || session.AbsoluteExpiresAt <= now)
            {
                session.RevokedAt ??= now;
                await _db.SaveChangesAsync();
                await CommitAsync(transaction);
                return InvalidRefreshToken();
            }

            if (!currentMatches && !previousMatches)
            {
                session.RevokedAt = now;
                await _db.SaveChangesAsync();
                await CommitAsync(transaction);
                return InvalidRefreshToken();
            }

            var user = await AccountQuery().SingleOrDefaultAsync(item => item.Id == session.AppUserId);
            if (user is null || user.Status != AuthStatuses.Active)
            {
                session.RevokedAt = now;
                await _db.SaveChangesAsync();
                await CommitAsync(transaction);
                return InvalidRefreshToken();
            }

            var rotated = CreateRefreshCredential(session.Id);
            session.PreviousTokenHash = session.CurrentTokenHash;
            session.PreviousTokenValidUntil = now.AddSeconds(_jwt.RefreshRetryGraceSeconds);
            session.CurrentTokenHash = rotated.Hash;
            session.LastUsedAt = now;
            session.IdleExpiresAt = Min(
                now.AddDays(_jwt.RefreshIdleExpirationDays),
                session.AbsoluteExpiresAt);
            await _db.SaveChangesAsync();
            await CommitAsync(transaction);

            return ServiceResult<AccountSessionResponse>.Success(
                CreateAccountSession(user, new RefreshCredential(rotated.Token, rotated.Hash, session.IdleExpiresAt)));
        }
        finally
        {
            if (transaction is not null)
                await transaction.DisposeAsync();
        }
    }

    public async Task LogoutAsync(string refreshToken)
    {
        if (!TryParseRefreshToken(refreshToken, out var sessionId, out var secret))
            return;

        var session = await _db.AppUserRefreshSessions.SingleOrDefaultAsync(item => item.Id == sessionId);
        if (session is null || session.RevokedAt is not null)
            return;

        var hash = HashSecret(secret);
        if (!HashesMatch(session.CurrentTokenHash, hash)
            && (session.PreviousTokenHash is null || !HashesMatch(session.PreviousTokenHash, hash)))
            return;

        session.RevokedAt = UtcNow;
        await _db.SaveChangesAsync();
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

        var expiresAt = UtcNow.AddMinutes(_jwt.AccessTokenExpirationMinutes);
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

    private AccountSessionResponse CreateAccountSession(AppUser user, RefreshCredential refresh)
    {
        var expiresAt = UtcNow.AddMinutes(_jwt.AccessTokenExpirationMinutes);
        return new AccountSessionResponse(
            CreateToken(user, expiresAt),
            expiresAt,
            refresh.Token,
            refresh.ExpiresAt,
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

    private async Task<RefreshCredential> CreateRefreshSessionAsync(AppUser user)
    {
        var now = UtcNow;
        var id = Guid.NewGuid();
        var credential = CreateRefreshCredential(id);
        var absoluteExpiresAt = now.AddDays(_jwt.RefreshAbsoluteExpirationDays);
        var idleExpiresAt = Min(now.AddDays(_jwt.RefreshIdleExpirationDays), absoluteExpiresAt);
        _db.AppUserRefreshSessions.Add(new AppUserRefreshSession
        {
            Id = id,
            AppUserId = user.Id,
            CurrentTokenHash = credential.Hash,
            CreatedAt = now,
            LastUsedAt = now,
            IdleExpiresAt = idleExpiresAt,
            AbsoluteExpiresAt = absoluteExpiresAt
        });
        await _db.SaveChangesAsync();
        return new RefreshCredential(credential.Token, credential.Hash, idleExpiresAt);
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

    private DateTime UtcNow => _timeProvider.GetUtcNow().UtcDateTime;

    private static DateTime Min(DateTime first, DateTime second) => first <= second ? first : second;

    private static (string Token, string Hash) CreateRefreshCredential(Guid sessionId)
    {
        var secret = RandomNumberGenerator.GetBytes(32);
        return ($"{sessionId:N}.{Base64UrlEncode(secret)}", HashSecret(secret));
    }

    private static bool TryParseRefreshToken(string token, out Guid sessionId, out byte[] secret)
    {
        sessionId = default;
        secret = [];
        var parts = token.Split('.', 2, StringSplitOptions.TrimEntries);
        if (parts.Length != 2 || !Guid.TryParseExact(parts[0], "N", out sessionId))
            return false;
        try
        {
            secret = Base64UrlDecode(parts[1]);
            return secret.Length == 32;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static string HashSecret(byte[] secret) => Convert.ToHexString(SHA256.HashData(secret));

    private static bool HashesMatch(string expected, string actual)
    {
        try
        {
            return CryptographicOperations.FixedTimeEquals(
                Convert.FromHexString(expected.Trim()),
                Convert.FromHexString(actual));
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static string Base64UrlEncode(byte[] value) => Convert.ToBase64String(value)
        .TrimEnd('=')
        .Replace('+', '-')
        .Replace('/', '_');

    private static byte[] Base64UrlDecode(string value)
    {
        var padded = value.Replace('-', '+').Replace('_', '/');
        padded += (padded.Length % 4) switch { 2 => "==", 3 => "=", _ => string.Empty };
        return Convert.FromBase64String(padded);
    }

    private static Task CommitAsync(IDbContextTransaction? transaction) =>
        transaction?.CommitAsync() ?? Task.CompletedTask;

    private static ServiceResult<AccountSessionResponse> InvalidAccountCredentials() =>
        ServiceResult<AccountSessionResponse>.Unauthorized(
            "Login failed.", "Email or password is incorrect.");

    private static ServiceResult<AccountSessionResponse> InvalidRefreshToken() =>
        ServiceResult<AccountSessionResponse>.Unauthorized(
            "Session expired.", "The refresh token is invalid or has expired.");

    private sealed record RefreshCredential(string Token, string Hash, DateTime ExpiresAt);
}
