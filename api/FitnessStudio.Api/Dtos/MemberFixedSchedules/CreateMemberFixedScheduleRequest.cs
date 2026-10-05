using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MemberFixedSchedules;

public class CreateMemberFixedScheduleRequest
{
    [Range(1, long.MaxValue)]
    public long MemberId { get; set; }

    [Range(1, long.MaxValue)]
    public long RecurringScheduleId { get; set; }

    public DateOnly StartsOn { get; set; }

    public DateOnly? EndsOn { get; set; }

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = "active";
}
