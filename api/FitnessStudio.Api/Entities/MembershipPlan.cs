using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class MembershipPlan
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public int DurationDays { get; set; }

    public int? SessionLimit { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public string? SessionLimitPeriod { get; set; }

    public decimal PriceAmount { get; set; }

    public string Currency { get; set; } = null!;

    public virtual ICollection<MemberMembership> MemberMemberships { get; set; } = new List<MemberMembership>();

    public virtual Studio Studio { get; set; } = null!;
}
