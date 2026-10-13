using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Auth;

public class RegisterRequest
{
    [Required, EmailAddress, StringLength(255)]
    public string Email { get; set; } = null!;

    [Required, StringLength(128, MinimumLength = 10)]
    public string Password { get; set; } = null!;
}
