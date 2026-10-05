using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;

namespace FitnessStudio.Api.Dtos.ClassTypes;

public class CreateClassTypeRequest
{
    [Required]
    [StringLength(120)]
    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    [Range(1, int.MaxValue)]
    public int DefaultDurationMinutes { get; set; }

    [Range(1, int.MaxValue)]
    public int DefaultCapacity { get; set; }

    [Required]
    [StringLength(30)]
    [AllowedClassTypeDifficultyLevel]
    public string DifficultyLevel { get; set; } = "all_levels";

    [Required]
    [StringLength(30)]
    [AllowedClassTypeStatus]
    public string Status { get; set; } = "active";
}
