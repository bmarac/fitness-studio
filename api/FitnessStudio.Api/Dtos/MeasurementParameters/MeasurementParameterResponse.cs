namespace FitnessStudio.Api.Dtos.MeasurementParameters;

public record MeasurementParameterResponse(
    long Id,
    string Code,
    string Name,
    string? Unit,
    string ValueType,
    string Source,
    string? CalculationType,
    decimal? MinValue,
    decimal? MaxValue,
    short DecimalPlaces,
    int SortOrder,
    string Status);
