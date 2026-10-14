namespace FitnessStudio.Api.Dtos.StudioSettings;

public record StudioConfigurationResponse(
    bool JoinByCodeEnabled,
    string? JoinCode,
    string RecipientName,
    string Iban,
    string PaymentModel,
    string PaymentReference,
    string PaymentDescription,
    IReadOnlyList<int> MemberReminderDays,
    IReadOnlyList<int> AdminReminderDays,
    TimeOnly NotificationTime,
    int CancellationCutoffHours,
    bool IsPaymentComplete);
