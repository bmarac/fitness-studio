namespace FitnessStudio.Api.Configuration;

public class FirebaseMessagingOptions
{
    public const string SectionName = "FirebaseMessaging";

    public bool Enabled { get; set; }
    public string? ProjectId { get; set; }
    public string? CredentialPath { get; set; }
    public bool UseApplicationDefaultCredentials { get; set; }
    public int PollSeconds { get; set; } = 30;
}
