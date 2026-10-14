namespace FitnessStudio.Api.Dtos.MemberFixedSchedules;

public record AvailableFixedScheduleMemberResponse(
    long Id,
    string FirstName,
    string LastName,
    string Email,
    string Status);
