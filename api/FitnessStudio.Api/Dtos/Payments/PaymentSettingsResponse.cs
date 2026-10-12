namespace FitnessStudio.Api.Dtos.Payments;

public record PaymentSettingsResponse(
    string RecipientName,
    string Iban,
    string PaymentModel,
    string PaymentReference,
    string PaymentDescription,
    IReadOnlyList<int> MemberReminderDays,
    IReadOnlyList<int> AdminReminderDays,
    TimeOnly NotificationTime,
    bool IsComplete);
