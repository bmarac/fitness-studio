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
    private readonly FitnessStudioDbContext _dbContext;
    private readonly JwtOptions _jwtOptions;
    private readonly IPasswordHasher<AppUser> _passwordHasher;

    public AuthService(
        FitnessStudioDbContext dbContext,
        IOptions<JwtOptions> jwtOptions,
        IPasswordHasher<AppUser> passwordHasher)
    {
        _dbContext = dbContext;
        _jwtOptions = jwtOptions.Value;
        _passwordHasher = passwordHasher;
    }

    public async Task<ServiceResult<LoginResponse>> LoginAsync(LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _dbContext.AppUsers
            .Include(appUser => appUser.Studio)
            .Include(appUser => appUser.AppUserRoles)
            .FirstOrDefaultAsync(appUser =>
                appUser.StudioId == request.StudioId
                && appUser.Email == email);

        if (user is null
            || user.Status != AuthStatuses.Active
            || user.Studio.Status != AuthStatuses.Active)
        {
            return InvalidCredentials();
        }

        var verificationResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);

        if (verificationResult == PasswordVerificationResult.Failed)
        {
            return InvalidCredentials();
        }

        if (verificationResult == PasswordVerificationResult.SuccessRehashNeeded)
        {
            user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);
        }

        user.LastLoginAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        var expiresAt = DateTime.UtcNow.AddMinutes(_jwtOptions.ExpirationMinutes);
        var accessToken = CreateAccessToken(user, expiresAt);

        return ServiceResult<LoginResponse>.Success(new LoginResponse(
            accessToken,
            expiresAt,
            new AuthenticatedUserResponse(
                user.Id,
                user.StudioId,
                user.MemberId,
                user.TrainerId,
                user.Email,
                user.AppUserRoles.Select(userRole => userRole.Role).ToArray())));
    }

    private string CreateAccessToken(AppUser user, DateTime expiresAt)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Email, user.Email),
            new(AuthClaimTypes.StudioId, user.StudioId.ToString())
        };

        claims.AddRange(user.AppUserRoles.Select(userRole =>
            new Claim(ClaimTypes.Role, userRole.Role)));

        if (user.MemberId.HasValue)
        {
            claims.Add(new Claim(AuthClaimTypes.MemberId, user.MemberId.Value.ToString()));
        }

        if (user.TrainerId.HasValue)
        {
            claims.Add(new Claim(AuthClaimTypes.TrainerId, user.TrainerId.Value.ToString()));
        }

        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtOptions.SigningKey));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _jwtOptions.Issuer,
            audience: _jwtOptions.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static ServiceResult<LoginResponse> InvalidCredentials()
    {
        return ServiceResult<LoginResponse>.Unauthorized(
            "Login failed.",
            "Studio, email or password is incorrect.");
    }
}
