using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class AppUserRole
{
    public long AppUserStudioId { get; set; }

    public string Role { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public virtual AppUserStudio AppUserStudio { get; set; } = null!;
}
