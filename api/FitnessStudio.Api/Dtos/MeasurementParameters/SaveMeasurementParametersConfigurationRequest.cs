using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MeasurementParameters;

public class SaveMeasurementParametersConfigurationRequest
{
    [Required]
    public List<MeasurementParameterConfigurationItemRequest> Items { get; set; } = [];
}

public class MeasurementParameterConfigurationItemRequest
{
    public long? Id { get; set; }

    [Required]
    [StringLength(120)]
    public string Name { get; set; } = null!;

    [StringLength(30)]
    public string? Unit { get; set; }

    public int SortOrder { get; set; }

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = "active";
}
