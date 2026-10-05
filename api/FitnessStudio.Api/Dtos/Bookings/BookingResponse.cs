namespace FitnessStudio.Api.Dtos.Bookings;

public class BookingResponse
{
    public long Id { get; set; }

    public long MemberId { get; set; }

    public string MemberFirstName { get; set; } = null!;

    public string MemberLastName { get; set; } = null!;

    public long ClassSessionId { get; set; }

    public string BookingSource { get; set; } = null!;

    public long? MemberFixedScheduleId { get; set; }

    public long ClassTypeId { get; set; }

    public string ClassTypeName { get; set; } = null!;

    public long TrainerId { get; set; }

    public string TrainerFirstName { get; set; } = null!;

    public string TrainerLastName { get; set; } = null!;

    public DateTime ClassSessionStartsAt { get; set; }

    public DateTime ClassSessionEndsAt { get; set; }

    public string Status { get; set; } = null!;

    public DateTime BookedAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    public DateTime? AttendedAt { get; set; }
}
