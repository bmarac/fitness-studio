namespace FitnessStudio.Api.Entities;

public class AppNotification
{
    public long Id { get; set; }
    public long StudioId { get; set; }
    public long AppUserId { get; set; }
    public long? PaymentObligationId { get; set; }
    public string NotificationType { get; set; } = null!;
    public int? DayOffset { get; set; }
    public string Title { get; set; } = null!;
    public string Body { get; set; } = null!;
    public DateTime? ReadAt { get; set; }
    public DateTime? PushedAt { get; set; }
    public DateTime CreatedAt { get; set; }

    public virtual AppUser AppUser { get; set; } = null!;
    public virtual MembershipPaymentObligation? PaymentObligation { get; set; }
    public virtual Studio Studio { get; set; } = null!;
}
