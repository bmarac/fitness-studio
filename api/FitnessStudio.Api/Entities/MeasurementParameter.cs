using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class MeasurementParameter
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public string Code { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? Unit { get; set; }

    public string ValueType { get; set; } = null!;

    public string Source { get; set; } = null!;

    public string? CalculationType { get; set; }

    public decimal? MinValue { get; set; }

    public decimal? MaxValue { get; set; }

    public short DecimalPlaces { get; set; }

    public int SortOrder { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<MemberMeasurementValue> MemberMeasurementValues { get; set; } = new List<MemberMeasurementValue>();

    public virtual Studio Studio { get; set; } = null!;
}
