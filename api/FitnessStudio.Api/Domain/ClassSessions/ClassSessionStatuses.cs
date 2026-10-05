namespace FitnessStudio.Api.Domain.ClassSessions;

public static class ClassSessionStatuses
{
    public const string Scheduled = "scheduled";
    public const string Cancelled = "cancelled";
    public const string Completed = "completed";

    public static readonly string[] All =
    [
        Scheduled,
        Cancelled,
        Completed
    ];

    public static bool IsValid(string status)
    {
        return All.Contains(status, StringComparer.OrdinalIgnoreCase);
    }
}
