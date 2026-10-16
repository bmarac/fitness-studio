using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Auth;

public class RefreshTokenRequest
{
    [Required]
    public string RefreshToken { get; set; } = null!;
}
