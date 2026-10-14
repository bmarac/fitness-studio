using System.ComponentModel.DataAnnotations;
using FitnessStudio.Api.Validation;

namespace FitnessStudio.Api.Dtos.ClassTypes;

public class SaveClassTypesConfigurationRequest
{
    [Required]
    public List<ClassTypeConfigurationItemRequest> Items { get; set; } = [];

    public List<long> DeletedIds { get; set; } = [];
}

public class ClassTypeConfigurationItemRequest
{
    public long? Id { get; set; }

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
