namespace FitnessStudio.Api.Dtos.MeasurementParameters;

public record MeasurementParameterResponse(
    long Id,
    string Code,
    string Name,
    string? Unit,
    int SortOrder,
    string Status);
