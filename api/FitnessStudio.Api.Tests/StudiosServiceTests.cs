using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Studios;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class StudiosServiceTests
{
    [Fact]
    public async Task GetReturnsOnlyCurrentStudio()
    {
        await using var db = Database();
        db.Studios.AddRange(
            Studio(1, "Current", "Europe/Zagreb"),
            Studio(2, "Foreign", "UTC"));
        await db.SaveChangesAsync();

        var result = await Service(db).GetCurrentStudioAsync();

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(1, result.Value!.Id);
        Assert.Equal("Current", result.Value.Name);
        Assert.Equal("Europe/Zagreb", result.Value.Timezone);
    }

    [Fact]
    public async Task GetReturnsNotFoundWhenCurrentStudioDoesNotExist()
    {
        await using var db = Database();
        db.Studios.Add(Studio(2, "Foreign", "UTC"));
        await db.SaveChangesAsync();

        var result = await Service(db).GetCurrentStudioAsync();

        Assert.Equal(ServiceResultStatus.NotFound, result.Status);
        Assert.Equal("Studio not found.", result.Error?.Title);
    }

    [Fact]
    public async Task UpdateRejectsUnknownTimezoneWithoutChangingStudio()
    {
        await using var db = Database();
        db.Studios.Add(Studio(1, "Original", "UTC"));
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateCurrentStudioAsync(new UpdateStudioRequest
        {
            Name = "Changed",
            Timezone = "Not/A-Timezone"
        });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Invalid timezone.", result.Error?.Title);
        Assert.Equal("Original", db.Studios.Find(1L)!.Name);
    }

    [Fact]
    public async Task UpdateTrimsAndPersistsCurrentStudioOnly()
    {
        await using var db = Database();
        db.Studios.AddRange(
            Studio(1, "Original", "UTC"),
            Studio(2, "Foreign", "UTC"));
        await db.SaveChangesAsync();
        var originalUpdatedAt = db.Studios.Find(1L)!.UpdatedAt;

        var result = await Service(db).UpdateCurrentStudioAsync(new UpdateStudioRequest
        {
            Name = " Updated studio ",
            Timezone = " Europe/Zagreb "
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var current = db.Studios.Find(1L)!;
        Assert.Equal("Updated studio", current.Name);
        Assert.Equal("Europe/Zagreb", current.Timezone);
        Assert.True(current.UpdatedAt >= originalUpdatedAt);
        Assert.Equal("Foreign", db.Studios.Find(2L)!.Name);
    }

    [Fact]
    public async Task UpdateReturnsNotFoundAfterTimezoneValidation()
    {
        await using var db = Database();

        var result = await Service(db).UpdateCurrentStudioAsync(new UpdateStudioRequest
        {
            Name = "Missing",
            Timezone = "UTC"
        });

        Assert.Equal(ServiceResultStatus.NotFound, result.Status);
        Assert.Equal("Studio not found.", result.Error?.Title);
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static StudiosService Service(FitnessStudioDbContext db) =>
        new(db, new Context());

    private static Studio Studio(long id, string name, string timezone) => new()
    {
        Id = id,
        Name = name,
        Timezone = timezone,
        Status = "active",
        CreatedAt = DateTime.UtcNow.AddDays(-1),
        UpdatedAt = DateTime.UtcNow.AddDays(-1)
    };

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string>();
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
