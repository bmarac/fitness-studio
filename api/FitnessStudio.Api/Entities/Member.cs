using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class Member
{
    public long Id { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public virtual AppUser? AppUser { get; set; }

    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();

    public virtual ICollection<MemberFixedSchedule> MemberFixedSchedules { get; set; } = new List<MemberFixedSchedule>();

    public virtual ICollection<MemberMeasurement> MemberMeasurements { get; set; } = new List<MemberMeasurement>();

    public virtual ICollection<MemberMembership> MemberMemberships { get; set; } = new List<MemberMembership>();

    public virtual Studio Studio { get; set; } = null!;
}
