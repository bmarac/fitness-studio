using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class RecurringClassSchedule
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public long ClassTypeId { get; set; }

    public long TrainerId { get; set; }

    public short DayOfWeek { get; set; }

    public TimeOnly StartsAtTime { get; set; }

    public int DurationMinutes { get; set; }

    public int Capacity { get; set; }

    public DateOnly ValidFrom { get; set; }

    public DateOnly? ValidUntil { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<ClassSession> ClassSessions { get; set; } = new List<ClassSession>();

    public virtual ClassType ClassType { get; set; } = null!;

    public virtual ICollection<MemberFixedSchedule> MemberFixedSchedules { get; set; } = new List<MemberFixedSchedule>();

    public virtual Studio Studio { get; set; } = null!;

    public virtual Trainer Trainer { get; set; } = null!;
}
