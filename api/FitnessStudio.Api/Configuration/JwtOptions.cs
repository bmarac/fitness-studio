namespace FitnessStudio.Api.Configuration;

public class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = null!;

    public string Audience { get; set; } = null!;

    public string SigningKey { get; set; } = null!;

    public int AccessTokenExpirationMinutes { get; set; } = 15;

    public int RefreshIdleExpirationDays { get; set; } = 30;

    public int RefreshAbsoluteExpirationDays { get; set; } = 90;

    public int RefreshRetryGraceSeconds { get; set; } = 30;
}
