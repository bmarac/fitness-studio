namespace FitnessStudio.Api.Dtos.MemberFixedSchedules;

public record MemberFixedScheduleResponse(
    long Id,
    long MemberId,
    string MemberName,
    long RecurringScheduleId,
    string ClassTypeName,
    string TrainerName,
    short DayOfWeek,
    TimeOnly StartsAtTime,
    DateOnly StartsOn,
    DateOnly? EndsOn,
    string Status);
