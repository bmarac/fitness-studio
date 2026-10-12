namespace FitnessStudio.Api.Entities;

public class MembershipPaymentObligation
{
    public long Id { get; set; }
    public long StudioId { get; set; }
    public long MemberMembershipId { get; set; }
    public DateOnly PeriodStartsOn { get; set; }
    public DateOnly PeriodEndsOn { get; set; }
    public DateOnly DueOn { get; set; }
    public string PlanName { get; set; } = null!;
    public decimal FullAmount { get; set; }
    public decimal AmountDue { get; set; }
    public string Currency { get; set; } = null!;
    public string Status { get; set; } = null!;
    public string RecipientName { get; set; } = null!;
    public string Iban { get; set; } = null!;
    public string PaymentModel { get; set; } = null!;
    public string PaymentReference { get; set; } = null!;
    public string PaymentDescription { get; set; } = null!;
    public DateTime? ReportedAt { get; set; }
    public long? ReportedByUserId { get; set; }
    public DateTime? ConfirmedAt { get; set; }
    public long? ConfirmedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public virtual MemberMembership MemberMembership { get; set; } = null!;
    public virtual Studio Studio { get; set; } = null!;
    public virtual AppUser? ReportedByUser { get; set; }
    public virtual AppUser? ConfirmedByUser { get; set; }
}
