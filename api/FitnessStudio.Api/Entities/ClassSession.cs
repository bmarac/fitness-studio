using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class ClassSession
{
    public long Id { get; set; }

    public long ClassTypeId { get; set; }

    public long TrainerId { get; set; }

    public DateTime StartsAt { get; set; }

    public DateTime EndsAt { get; set; }

    public int Capacity { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public long? RecurringScheduleId { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ClassType ClassType { get; set; } = null!;

    public virtual RecurringClassSchedule? RecurringSchedule { get; set; }

    public virtual Studio Studio { get; set; } = null!;

    public virtual Trainer Trainer { get; set; } = null!;
}
