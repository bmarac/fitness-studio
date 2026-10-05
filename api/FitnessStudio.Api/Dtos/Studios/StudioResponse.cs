namespace FitnessStudio.Api.Dtos.Studios;

public record StudioResponse(
    long Id,
    string Name,
    string Timezone,
    string Status);
