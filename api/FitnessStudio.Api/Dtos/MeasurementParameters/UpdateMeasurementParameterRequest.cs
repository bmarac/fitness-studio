using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MeasurementParameters;

public class UpdateMeasurementParameterRequest
{
    [Required]
    [StringLength(120)]
    public string Name { get; set; } = null!;

    [StringLength(30)]
    public string? Unit { get; set; }

    [Required]
    [StringLength(20)]
    public string ValueType { get; set; } = null!;

    [Required]
    [StringLength(20)]
    public string Source { get; set; } = null!;

    [StringLength(30)]
    public string? CalculationType { get; set; }

    public decimal? MinValue { get; set; }

    public decimal? MaxValue { get; set; }

    [Range(0, 4)]
    public short DecimalPlaces { get; set; }

    public int SortOrder { get; set; }

    [Required]
    [StringLength(30)]
    public string Status { get; set; } = null!;
}
