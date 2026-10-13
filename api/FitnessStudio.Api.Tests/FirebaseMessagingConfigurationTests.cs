using FitnessStudio.Api.Configuration;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class FirebaseMessagingConfigurationTests
{
    [Fact]
    public void DisabledPushDoesNotRequireFirebaseCredentials()
    {
        using var provider = Build(new Dictionary<string, string?>
        {
            ["FirebaseMessaging:Enabled"] = "false"
        });

        var options = provider.GetRequiredService<IOptions<FirebaseMessagingOptions>>().Value;

        Assert.False(options.Enabled);
    }

    [Fact]
    public void EnabledPushRequiresProjectAndCredentials()
    {
        using var provider = Build(new Dictionary<string, string?>
        {
            ["FirebaseMessaging:Enabled"] = "true"
        });

        var error = Assert.Throws<OptionsValidationException>(
            () => provider.GetRequiredService<IOptions<FirebaseMessagingOptions>>().Value);

        Assert.Contains("ProjectId", error.Message);
        Assert.Contains("CredentialPath", error.Message);
    }

    [Fact]
    public void ApplicationDefaultCredentialsDoNotRequireAFile()
    {
        using var provider = Build(new Dictionary<string, string?>
        {
            ["FirebaseMessaging:Enabled"] = "true",
            ["FirebaseMessaging:ProjectId"] = "fitness-studio",
            ["FirebaseMessaging:UseApplicationDefaultCredentials"] = "true"
        });

        var options = provider.GetRequiredService<IOptions<FirebaseMessagingOptions>>().Value;

        Assert.True(options.Enabled);
        Assert.True(options.UseApplicationDefaultCredentials);
    }

    [Fact]
    public void CredentialPathMustPointToAnExistingFile()
    {
        using var provider = Build(new Dictionary<string, string?>
        {
            ["FirebaseMessaging:Enabled"] = "true",
            ["FirebaseMessaging:ProjectId"] = "fitness-studio",
            ["FirebaseMessaging:CredentialPath"] = "/path/that/does/not/exist.json"
        });

        var error = Assert.Throws<OptionsValidationException>(
            () => provider.GetRequiredService<IOptions<FirebaseMessagingOptions>>().Value);

        Assert.Contains("readable service-account file", error.Message);
    }

    private static ServiceProvider Build(Dictionary<string, string?> values)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(values)
            .Build();
        var services = new ServiceCollection();
        services.AddFirebaseMessagingConfiguration(configuration);
        return services.BuildServiceProvider();
    }
}
