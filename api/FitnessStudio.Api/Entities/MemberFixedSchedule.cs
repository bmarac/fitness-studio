using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class MemberFixedSchedule
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public long MemberId { get; set; }

    public long RecurringScheduleId { get; set; }

    public DateOnly StartsOn { get; set; }

    public DateOnly? EndsOn { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual Member Member { get; set; } = null!;

    public virtual RecurringClassSchedule RecurringSchedule { get; set; } = null!;

    public virtual Studio Studio { get; set; } = null!;
}
