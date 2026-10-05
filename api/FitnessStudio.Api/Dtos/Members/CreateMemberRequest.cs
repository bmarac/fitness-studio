using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;

namespace FitnessStudio.Api.Dtos.Members;

public class CreateMemberRequest
{
    [Required]
    [StringLength(100)]
    public string FirstName { get; set; } = null!;

    [Required]
    [StringLength(100)]
    public string LastName { get; set; } = null!;

    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; } = null!;

    [StringLength(50)]
    public string? Phone { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    [Required]
    [StringLength(30)]
    [AllowedMemberStatus]
    public string Status { get; set; } = "active";
}
