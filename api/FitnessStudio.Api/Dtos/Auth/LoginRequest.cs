using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Auth;

public class LoginRequest
{
    [Range(1, long.MaxValue)]
    public long StudioId { get; set; }

    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; } = null!;

    [Required]
    public string Password { get; set; } = null!;
}
