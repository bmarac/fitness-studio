using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class Trainer
{
    public long Id { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Bio { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public virtual AppUser? AppUser { get; set; }

    public virtual ICollection<ClassSession> ClassSessions { get; set; } = new List<ClassSession>();

    public virtual ICollection<RecurringClassSchedule> RecurringClassSchedules { get; set; } = new List<RecurringClassSchedule>();

    public virtual Studio Studio { get; set; } = null!;
}
