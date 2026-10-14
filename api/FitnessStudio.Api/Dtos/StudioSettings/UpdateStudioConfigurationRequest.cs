using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.StudioSettings;

public class UpdateStudioConfigurationRequest
{
    public bool JoinByCodeEnabled { get; set; }

    [StringLength(32)]
    public string? JoinCode { get; set; }

    [Required, StringLength(100)]
    public string RecipientName { get; set; } = null!;

    [Required, StringLength(34)]
    public string Iban { get; set; } = null!;

    [Required, RegularExpression("^HR[0-9]{2}$")]
    public string PaymentModel { get; set; } = "HR00";

    [Required, StringLength(22)]
    public string PaymentReference { get; set; } = null!;

    [Required, StringLength(35)]
    public string PaymentDescription { get; set; } = null!;

    public IReadOnlyList<int> MemberReminderDays { get; set; } = [0, 1];

    public IReadOnlyList<int> AdminReminderDays { get; set; } = [2];

    public TimeOnly NotificationTime { get; set; } = new(9, 0);

    [Range(0, 168)]
    public int CancellationCutoffHours { get; set; } = 12;
}
