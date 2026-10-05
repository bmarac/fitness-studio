using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class AppUser
{
    public long Id { get; set; }

    public long StudioId { get; set; }

    public long? MemberId { get; set; }

    public long? TrainerId { get; set; }

    public string Email { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime? LastLoginAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<AppUserRole> AppUserRoles { get; set; } = new List<AppUserRole>();

    public virtual Member? Member { get; set; }

    public virtual ICollection<MemberMeasurement> MemberMeasurements { get; set; } = new List<MemberMeasurement>();

    public virtual Studio Studio { get; set; } = null!;

    public virtual Trainer? Trainer { get; set; }
}
