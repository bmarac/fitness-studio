using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class MemberMeasurementValue
{
    public long Id { get; set; }

    public long MeasurementId { get; set; }

    public long ParameterId { get; set; }

    public decimal NumericValue { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual MemberMeasurement Measurement { get; set; } = null!;

    public virtual MeasurementParameter Parameter { get; set; } = null!;
}
