using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.Auth;

public class StudioCodeRequest
{
    [Required, StringLength(32, MinimumLength = 3)]
    public string Code { get; set; } = null!;
}

public class JoinStudioRequest : StudioCodeRequest
{
    [StringLength(100)]
    public string? FirstName { get; set; }

    [StringLength(100)]
    public string? LastName { get; set; }
}

public record StudioLookupResponse(
    long StudioId,
    string StudioName,
    bool RequiresProfileDetails,
    string Role);
