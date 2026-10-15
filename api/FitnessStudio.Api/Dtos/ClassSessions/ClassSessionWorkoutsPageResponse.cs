namespace FitnessStudio.Api.Dtos.ClassSessions;

public class ClassSessionWorkoutsPageResponse
{
    public List<ClassSessionResponse> Items { get; set; } = [];

    public int Page { get; set; }

    public int PageSize { get; set; }

    public bool HasNextPage { get; set; }
}
