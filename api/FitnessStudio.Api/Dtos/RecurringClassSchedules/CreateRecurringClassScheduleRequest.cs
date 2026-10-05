using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.RecurringClassSchedules;

public class CreateRecurringClassScheduleRequest
{
    [Range(1, long.MaxValue)]
    public long ClassTypeId { get; set; }

    [Range(1, long.MaxValue)]
    public long TrainerId { get; set; }

    [Range(1, 7)]
    public short DayOfWeek { get; set; }

    public TimeOnly StartsAtTime { get; set; }

    [Range(1, int.MaxValue)]
    public int DurationMinutes { get; set; }

    [Range(1, int.MaxValue)]
    public int Capacity { get; set; }

    public DateOnly ValidFrom { get; set; }

    public DateOnly? ValidUntil { get; set; }

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = "active";
}
