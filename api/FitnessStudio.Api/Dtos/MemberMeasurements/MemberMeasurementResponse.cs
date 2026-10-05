namespace FitnessStudio.Api.Dtos.MemberMeasurements;

public record MemberMeasurementResponse(
    long Id,
    long MemberId,
    DateTime MeasuredAt,
    long? RecordedByUserId,
    string? Note,
    IReadOnlyCollection<MemberMeasurementValueResponse> Values);

public record MemberMeasurementValueResponse(
    long ParameterId,
    string Code,
    string Name,
    string? Unit,
    decimal Value,
    short DecimalPlaces,
    int SortOrder,
    string Source);
