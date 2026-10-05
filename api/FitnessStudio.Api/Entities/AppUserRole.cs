using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class AppUserRole
{
    public long AppUserId { get; set; }

    public string Role { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public virtual AppUser AppUser { get; set; } = null!;
}
