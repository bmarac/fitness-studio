using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MemberMemberships;

public class CreateMemberMembershipRequest
{
    [Range(1, long.MaxValue)]
    public long MemberId { get; set; }

    [Range(1, long.MaxValue)]
    public long MembershipPlanId { get; set; }

    public DateOnly StartsOn { get; set; }

    public DateOnly EndsOn { get; set; }

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = "active";
}
