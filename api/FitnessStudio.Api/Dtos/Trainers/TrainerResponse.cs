namespace FitnessStudio.Api.Dtos.Trainers;

public class TrainerResponse
{
    public long Id { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Bio { get; set; }

    public string Status { get; set; } = null!;
}
