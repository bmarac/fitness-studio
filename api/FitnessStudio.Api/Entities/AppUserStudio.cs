namespace FitnessStudio.Api.Entities;

public class AppUserStudio
{
    public long Id { get; set; }
    public long AppUserId { get; set; }
    public long StudioId { get; set; }
    public long? MemberId { get; set; }
    public long? TrainerId { get; set; }
    public string Status { get; set; } = null!;
    public DateTime JoinedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public AppUser AppUser { get; set; } = null!;
    public Studio Studio { get; set; } = null!;
    public Member? Member { get; set; }
    public Trainer? Trainer { get; set; }
    public ICollection<AppUserRole> Roles { get; set; } = new List<AppUserRole>();
}
