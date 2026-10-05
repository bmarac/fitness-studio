namespace FitnessStudio.Api.Dtos.ClassTypes;

public class ClassTypeResponse
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public int DefaultDurationMinutes { get; set; }

    public int DefaultCapacity { get; set; }

    public string DifficultyLevel { get; set; } = null!;

    public string Status { get; set; } = null!;
}
