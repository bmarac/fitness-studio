using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.StudioSettings;

public class UpsertStudioSettingRequest
{
    [Required]
    public string Value { get; set; } = null!;

    [Required]
    [StringLength(30)]
    public string ValueType { get; set; } = null!;
}
