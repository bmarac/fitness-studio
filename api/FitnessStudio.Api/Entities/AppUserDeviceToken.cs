namespace FitnessStudio.Api.Entities;

public class AppUserDeviceToken
{
    public long Id { get; set; }
    public long AppUserId { get; set; }
    public string Token { get; set; } = null!;
    public string Platform { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public virtual AppUser AppUser { get; set; } = null!;
}
