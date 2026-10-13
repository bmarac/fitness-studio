using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Auth;

public class LoginRequest
{
    [Required]
    [EmailAddress]
    [StringLength(255)]
    public string Email { get; set; } = null!;

    [Required]
    public string Password { get; set; } = null!;

}
