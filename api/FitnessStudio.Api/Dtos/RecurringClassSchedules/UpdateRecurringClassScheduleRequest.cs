using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.RecurringClassSchedules;

public class UpdateRecurringClassScheduleRequest
{
    [Range(1, long.MaxValue)]
    public long TrainerId { get; set; }

    [Range(1, 7)]
    public short DayOfWeek { get; set; }

    public TimeOnly StartsAtTime { get; set; }

    [Range(1, int.MaxValue)]
    public int Capacity { get; set; }

    public DateOnly EffectiveFrom { get; set; }
}
