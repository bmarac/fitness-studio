using Microsoft.Extensions.Options;

namespace FitnessStudio.Api.Configuration;

public static class FirebaseMessagingServiceCollectionExtensions
{
    public static IServiceCollection AddFirebaseMessagingConfiguration(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddOptions<FirebaseMessagingOptions>()
            .Bind(configuration.GetSection(FirebaseMessagingOptions.SectionName))
            .Validate(
                options => !options.Enabled || !string.IsNullOrWhiteSpace(options.ProjectId),
                "FirebaseMessaging:ProjectId is required when push notifications are enabled.")
            .Validate(
                options => !options.Enabled || options.UseApplicationDefaultCredentials
                    || !string.IsNullOrWhiteSpace(options.CredentialPath),
                "FirebaseMessaging:CredentialPath is required unless application default credentials are enabled.")
            .Validate(
                options => !options.Enabled || options.UseApplicationDefaultCredentials
                    || File.Exists(options.CredentialPath),
                "FirebaseMessaging:CredentialPath must point to a readable service-account file.")
            .ValidateOnStart();
        return services;
    }
}
