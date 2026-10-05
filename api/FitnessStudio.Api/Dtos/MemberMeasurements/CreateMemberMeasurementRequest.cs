using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.MemberMeasurements;

public class CreateMemberMeasurementRequest
{
    public DateTime MeasuredAt { get; set; }

    [StringLength(2000)]
    public string? Note { get; set; }

    [Required]
    [MinLength(1)]
    public List<CreateMemberMeasurementValueRequest> Values { get; set; } = [];
}

public class CreateMemberMeasurementValueRequest
{
    [Range(1, long.MaxValue)]
    public long ParameterId { get; set; }

    public decimal Value { get; set; }
}
