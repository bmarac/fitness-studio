namespace FitnessStudio.Api.Dtos.ClassSessions;

public class ClassSessionResponse
{
    public long Id { get; set; }

    public long ClassTypeId { get; set; }

    public string ClassTypeName { get; set; } = null!;

    public long TrainerId { get; set; }

    public string TrainerFirstName { get; set; } = null!;

    public string TrainerLastName { get; set; } = null!;

    public DateTime StartsAt { get; set; }

    public DateTime EndsAt { get; set; }

    public int Capacity { get; set; }

    public int BookedCount { get; set; }

    public string Status { get; set; } = null!;
}
