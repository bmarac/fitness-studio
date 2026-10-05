namespace FitnessStudio.Api.Dtos.StudioSettings;

public record StudioSettingResponse(
    long Id,
    string Setting,
    string Value,
    string ValueType);
