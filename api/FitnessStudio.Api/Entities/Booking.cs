using System;
using System.Collections.Generic;

namespace FitnessStudio.Api.Entities;

public partial class Booking
{
    public long Id { get; set; }

    public long MemberId { get; set; }

    public long ClassSessionId { get; set; }

    public string Status { get; set; } = null!;

    public DateTime BookedAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    public DateTime? AttendedAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public long StudioId { get; set; }

    public string BookingSource { get; set; } = null!;

    public long? MakeupForBookingId { get; set; }

    public virtual ClassSession ClassSession { get; set; } = null!;

    public virtual Booking? InverseMakeupForBooking { get; set; }

    public virtual Booking? MakeupForBooking { get; set; }

    public virtual Member Member { get; set; } = null!;

    public virtual Studio Studio { get; set; } = null!;
}
