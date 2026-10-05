using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class Studio
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string Timezone { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<AppUser> AppUsers { get; set; } = new List<AppUser>();

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<ClassSession> ClassSessions { get; set; } = new List<ClassSession>();

    public virtual ICollection<ClassType> ClassTypes { get; set; } = new List<ClassType>();

    public virtual ICollection<MeasurementParameter> MeasurementParameters { get; set; } = new List<MeasurementParameter>();

    public virtual ICollection<MemberFixedSchedule> MemberFixedSchedules { get; set; } = new List<MemberFixedSchedule>();

    public virtual ICollection<MemberMeasurement> MemberMeasurements { get; set; } = new List<MemberMeasurement>();

    public virtual ICollection<MemberMembership> MemberMemberships { get; set; } = new List<MemberMembership>();

    public virtual ICollection<Member> Members { get; set; } = new List<Member>();

    public virtual ICollection<MembershipPlan> MembershipPlans { get; set; } = new List<MembershipPlan>();

    public virtual ICollection<RecurringClassSchedule> RecurringClassSchedules { get; set; } = new List<RecurringClassSchedule>();

    public virtual ICollection<StudioSetting> StudioSettings { get; set; } = new List<StudioSetting>();

    public virtual ICollection<Trainer> Trainers { get; set; } = new List<Trainer>();
}
