namespace FitnessStudio.Api.Dtos.Members;

public class MemberResponse
{
    public long Id { get; set; }

    public string FirstName { get; set; } = null!;

    public string LastName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public DateOnly? DateOfBirth { get; set; }

    public string Status { get; set; } = null!;
}
