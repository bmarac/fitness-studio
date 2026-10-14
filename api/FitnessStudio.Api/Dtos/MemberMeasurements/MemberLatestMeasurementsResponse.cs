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
    int SortOrder,
    DateTime MeasuredAt);
