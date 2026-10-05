using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class MemberMeasurement
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public long MemberId { get; set; }

    public DateTime MeasuredAt { get; set; }

    public long? RecordedByUserId { get; set; }

    public string? Note { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual Member Member { get; set; } = null!;

    public virtual ICollection<MemberMeasurementValue> MemberMeasurementValues { get; set; } = new List<MemberMeasurementValue>();

    public virtual AppUser? RecordedByUser { get; set; }

    public virtual Studio Studio { get; set; } = null!;
}
