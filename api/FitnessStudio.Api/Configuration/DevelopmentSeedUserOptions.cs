namespace FitnessStudio.Api.Configuration;

public class DevelopmentSeedUserOptions
{
    public const string SectionName = "DevelopmentSeedUser";

    public bool Enabled { get; set; }

    public List<DevelopmentSeedAccountOptions> Accounts { get; set; } = [];
}

public class DevelopmentSeedAccountOptions
{
    public long StudioId { get; set; }

    public string Email { get; set; } = null!;

    public string Password { get; set; } = null!;

    public List<string> Roles { get; set; } = [];
}
