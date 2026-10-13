using FitnessStudio.Api.Data;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class PushNotificationProcessorTests
{
    [Fact]
    public async Task SuccessfulDeliveryMarksNotificationAsPushed()
    {
        await using var db = CreateDatabase();
        Seed(db, "valid-token");
        var sender = new FakeSender(PushDeliveryResult.Delivered);

        await new PushNotificationProcessor(
            db,
            sender,
            NullLogger<PushNotificationProcessor>.Instance).ProcessAsync();

        Assert.NotNull(db.AppNotifications.Single().PushedAt);
        Assert.Single(sender.Messages);
    }

    [Fact]
    public async Task TemporaryFailureIsRetriedAndInvalidTokenIsRemoved()
    {
        await using var db = CreateDatabase();
        Seed(db, "retry-token", "invalid-token");
        var sender = new FakeSender(PushDeliveryResult.Retry);
        sender.Results["invalid-token"] = PushDeliveryResult.InvalidToken;
        var processor = new PushNotificationProcessor(
            db,
            sender,
            NullLogger<PushNotificationProcessor>.Instance);

        await processor.ProcessAsync();
        await processor.ProcessAsync();

        Assert.Null(db.AppNotifications.Single().PushedAt);
        Assert.Equal(2, sender.Messages.Count(item => item.Token == "retry-token"));
        Assert.DoesNotContain(db.AppUserDeviceTokens, item => item.Token == "invalid-token");
    }

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static void Seed(FitnessStudioDbContext db, params string[] tokens)
    {
        var user = new AppUser
        {
            Id = 10, Email = "admin@example.com", PasswordHash = "unused", Status = "active",
            CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow
        };
        var studio = new Studio
        {
            Id = 1, Name = "Stay Fit", Timezone = "Europe/Zagreb", Status = "active",
            CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow
        };
        db.AddRange(user, studio, new AppNotification
        {
            Id = 5, AppUser = user, Studio = studio, NotificationType = "member_joined",
            Title = "Joined", Body = "A new member joined.", CreatedAt = DateTime.UtcNow
        });
        foreach (var token in tokens)
            db.AppUserDeviceTokens.Add(new AppUserDeviceToken
            {
                AppUser = user, Token = token, Platform = "android",
                CreatedAt = DateTime.UtcNow, UpdatedAt = DateTime.UtcNow
            });
        db.SaveChanges();
    }

    private sealed class FakeSender(PushDeliveryResult defaultResult) : IPushNotificationSender
    {
        public bool IsEnabled => true;
        public Dictionary<string, PushDeliveryResult> Results { get; } = [];
        public List<(PushMessage Message, string Token)> Messages { get; } = [];

        public Task<PushDeliveryResult> SendAsync(
            PushMessage message, string token, CancellationToken cancellationToken)
        {
            Messages.Add((message, token));
            return Task.FromResult(Results.GetValueOrDefault(token, defaultResult));
        }
    }
}
