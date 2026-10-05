namespace FitnessStudio.Api.Dtos.RecurringClassSchedules;

public record RecurringClassScheduleResponse(
    long Id,
    long ClassTypeId,
    string ClassTypeName,
    long TrainerId,
    string TrainerName,
    short DayOfWeek,
    TimeOnly StartsAtTime,
    int DurationMinutes,
    int Capacity,
    DateOnly ValidFrom,
    DateOnly? ValidUntil,
    string Status);
