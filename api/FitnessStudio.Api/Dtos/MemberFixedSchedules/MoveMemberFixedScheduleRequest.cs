using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MemberFixedSchedules;

public class MoveMemberFixedScheduleRequest
{
    [Range(1, long.MaxValue)]
    public long TargetRecurringScheduleId { get; set; }
}
