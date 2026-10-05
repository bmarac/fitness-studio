using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class ClassType
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public int DefaultDurationMinutes { get; set; }

    public int DefaultCapacity { get; set; }

    public string DifficultyLevel { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public virtual ICollection<ClassSession> ClassSessions { get; set; } = new List<ClassSession>();

    public virtual ICollection<RecurringClassSchedule> RecurringClassSchedules { get; set; } = new List<RecurringClassSchedule>();

    public virtual Studio Studio { get; set; } = null!;
}
