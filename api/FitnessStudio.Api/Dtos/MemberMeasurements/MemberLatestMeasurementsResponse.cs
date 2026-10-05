namespace FitnessStudio.Api.Dtos.MemberMeasurements;

public record MemberLatestMeasurementsResponse(
    long MemberId,
    IReadOnlyCollection<MemberLatestMeasurementValueResponse> Values);

public record MemberLatestMeasurementValueResponse(
    long ParameterId,
    string Code,
    string Name,
    string? Unit,
    decimal Value,
    short DecimalPlaces,
    int SortOrder,
    string Source,
    DateTime MeasuredAt);
