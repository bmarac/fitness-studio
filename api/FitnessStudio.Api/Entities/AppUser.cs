using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class AppUser
{
    public long Id { get; set; }

    public string Email { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime? LastLoginAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<AppUserStudio> StudioMemberships { get; set; } = new List<AppUserStudio>();

    public virtual ICollection<AppNotification> AppNotifications { get; set; } = new List<AppNotification>();

    public virtual ICollection<AppUserDeviceToken> DeviceTokens { get; set; } = new List<AppUserDeviceToken>();

    public virtual ICollection<MemberMeasurement> MemberMeasurements { get; set; } = new List<MemberMeasurement>();
}
