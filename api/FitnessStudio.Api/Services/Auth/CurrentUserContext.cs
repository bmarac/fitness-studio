using System.Security.Claims;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Services.Interfaces;

namespace FitnessStudio.Api.Services.Auth;

public class CurrentUserContext : ICurrentUserContext
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserContext(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public long UserId => GetRequiredLongClaim(ClaimTypes.NameIdentifier);

    public string Email => GetRequiredClaim(ClaimTypes.Email);

    public long StudioId => GetRequiredLongClaim(AuthClaimTypes.StudioId);

    public long? MemberId => GetOptionalLongClaim(AuthClaimTypes.MemberId);

    public long? TrainerId => GetOptionalLongClaim(AuthClaimTypes.TrainerId);

    public IReadOnlySet<string> Roles => _httpContextAccessor.HttpContext?.User
        .FindAll(ClaimTypes.Role)
        .Select(claim => claim.Value)
        .ToHashSet(StringComparer.OrdinalIgnoreCase)
        ?? new HashSet<string>(StringComparer.OrdinalIgnoreCase);

    public bool IsMemberOnly => IsInRole(AuthRoles.Member)
        && !IsInRole(AuthRoles.Admin)
        && !IsInRole(AuthRoles.Trainer);

    public bool IsInRole(string role)
    {
        return Roles.Contains(role);
    }

    private string GetRequiredClaim(string claimType)
    {
        return _httpContextAccessor.HttpContext?.User.FindFirstValue(claimType)
            ?? throw new InvalidOperationException($"Authenticated user is missing the '{claimType}' claim.");
    }

    private long GetRequiredLongClaim(string claimType)
    {
        var value = GetRequiredClaim(claimType);

        return long.TryParse(value, out var parsedValue)
            ? parsedValue
            : throw new InvalidOperationException($"Authenticated user has an invalid '{claimType}' claim.");
    }

    private long? GetOptionalLongClaim(string claimType)
    {
        var value = _httpContextAccessor.HttpContext?.User.FindFirstValue(claimType);

        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return long.TryParse(value, out var parsedValue)
            ? parsedValue
            : throw new InvalidOperationException($"Authenticated user has an invalid '{claimType}' claim.");
    }
}
