using System.ComponentModel.DataAnnotations;

namespace FitnessStudio.Api.Dtos.ClassSessions;

public class ClassSessionWorkoutsQuery
{
    [RegularExpression("^(active|completed|cancelled|all)$")]
    public string Filter { get; set; } = "active";

    [Range(1, int.MaxValue)]
    public int Page { get; set; } = 1;

    [Range(1, 100)]
    public int PageSize { get; set; } = 20;

    [Range(1, long.MaxValue)]
    public long? TrainerId { get; set; }
}
