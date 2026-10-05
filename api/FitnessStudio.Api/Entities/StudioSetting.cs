using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class StudioSetting
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public string Setting { get; set; } = null!;

    public string Value { get; set; } = null!;

    public string ValueType { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual Studio Studio { get; set; } = null!;
}
