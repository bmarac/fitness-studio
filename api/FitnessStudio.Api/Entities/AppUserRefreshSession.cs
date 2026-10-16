namespace FitnessStudio.Api.Entities;

public class AppUserRefreshSession
{
    public Guid Id { get; set; }
    public long AppUserId { get; set; }
    public string CurrentTokenHash { get; set; } = null!;
    public string? PreviousTokenHash { get; set; }
    public DateTime? PreviousTokenValidUntil { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastUsedAt { get; set; }
    public DateTime IdleExpiresAt { get; set; }
    public DateTime AbsoluteExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }

    public virtual AppUser AppUser { get; set; } = null!;
}
