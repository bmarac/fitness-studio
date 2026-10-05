using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;

namespace FitnessStudio.Api.Dtos.ClassSessions;

public class CreateClassSessionRequest
{
    [Range(1, long.MaxValue)]
    public long ClassTypeId { get; set; }

    [Range(1, long.MaxValue)]
    public long TrainerId { get; set; }

    [Range(1, long.MaxValue)]
    public long? RecurringScheduleId { get; set; }

    public DateTime StartsAt { get; set; }

    public DateTime EndsAt { get; set; }

    [Range(1, int.MaxValue)]
    public int Capacity { get; set; }

    [Required]
    [StringLength(30)]
    [AllowedClassSessionStatus]
    public string Status { get; set; } = "scheduled";
}
