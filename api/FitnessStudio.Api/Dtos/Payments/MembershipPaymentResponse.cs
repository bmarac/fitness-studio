namespace FitnessStudio.Api.Dtos.Payments;

public record MembershipPaymentResponse(
    long Id,
    long MemberMembershipId,
    long MemberId,
    string MemberName,
    string PlanName,
    DateOnly PeriodStartsOn,
    DateOnly PeriodEndsOn,
    DateOnly DueOn,
    decimal FullAmount,
    decimal AmountDue,
    string Currency,
    string Status,
    bool IsOverdue,
    string RecipientName,
    string Iban,
    string PaymentModel,
    string PaymentReference,
    string PaymentDescription,
    DateTime? ReportedAt,
    DateTime? ConfirmedAt,
    string BarcodeUrl);

public record MembershipPaymentSummaryResponse(int Pending, int Reported, int Overdue, int Paid);
