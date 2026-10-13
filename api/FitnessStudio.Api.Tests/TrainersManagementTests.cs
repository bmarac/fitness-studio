using System.Reflection;
using AutoMapper;
using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Profiles;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Trainers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class TrainersManagementTests
{
    [Fact]
    public async Task CreateNormalizesEmailAndRejectsAnExistingMemberEmail()
    {
        await using var db = CreateDatabase();
        db.AddRange(
            Studio(),
            new Member
            {
                StudioId = 1,
                FirstName = "Ana",
                LastName = "Horvat",
                Email = "ana@example.com",
                Status = AuthStatuses.Active,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        await db.SaveChangesAsync();
        var service = CreateService(db);

        var created = await service.CreateTrainerAsync(new CreateTrainerRequest
        {
            FirstName = " Filip ",
            LastName = " Šarić ",
            Email = " FILIP@EXAMPLE.COM ",
            Status = AuthStatuses.Active
        });
        var conflict = await service.CreateTrainerAsync(new CreateTrainerRequest
        {
            FirstName = "Ana",
            LastName = "Coach",
            Email = " ANA@EXAMPLE.COM ",
            Status = AuthStatuses.Active
        });

        Assert.Equal(ServiceResultStatus.Success, created.Status);
        Assert.Equal("filip@example.com", created.Value!.Email);
        Assert.Equal("filip@example.com", db.Trainers.Single().Email);
        Assert.Equal(ServiceResultStatus.Conflict, conflict.Status);
    }

    [Fact]
    public async Task UpdateNormalizesEmailAndRejectsAnotherTrainerEmail()
    {
        await using var db = CreateDatabase();
        db.AddRange(
            Studio(),
            Trainer(10, "first@example.com"),
            Trainer(11, "second@example.com"));
        await db.SaveChangesAsync();
        var service = CreateService(db);

        var conflict = await service.UpdateTrainerAsync(10, new UpdateTrainerRequest
        {
            FirstName = "First",
            LastName = "Trainer",
            Email = " SECOND@EXAMPLE.COM ",
            Status = AuthStatuses.Active
        });
        var updated = await service.UpdateTrainerAsync(10, new UpdateTrainerRequest
        {
            FirstName = "First",
            LastName = "Trainer",
            Email = " NEW@EXAMPLE.COM ",
            Status = AuthStatuses.Active
        });

        Assert.Equal(ServiceResultStatus.Conflict, conflict.Status);
        Assert.Equal(ServiceResultStatus.Success, updated.Status);
        Assert.Equal("new@example.com", db.Trainers.Single(item => item.Id == 10).Email);
    }

    [Fact]
    public void TrainerWritesRequireAdminAndMemberCreationEndpointsAreAbsent()
    {
        var writeActions = new[]
        {
            nameof(TrainersController.CreateTrainer),
            nameof(TrainersController.UpdateTrainer),
            nameof(TrainersController.DeleteTrainer)
        };

        foreach (var action in writeActions)
        {
            var authorize = typeof(TrainersController).GetMethod(action)!
                .GetCustomAttribute<AuthorizeAttribute>();
            Assert.Equal(AuthRoles.Admin, authorize?.Roles);
        }

        Assert.DoesNotContain(
            typeof(MembersController).GetMethods(),
            method => method.GetCustomAttribute<HttpPostAttribute>() is not null);
        Assert.DoesNotContain(
            typeof(TrainersController).Assembly.GetTypes(),
            type => type.Name == "OnboardingController");
    }

    private static FitnessStudioDbContext CreateDatabase() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static TrainersService CreateService(FitnessStudioDbContext db)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(_ => { }, typeof(TrainerProfile).Assembly);
        using var provider = services.BuildServiceProvider();
        return new TrainersService(
            db,
            provider.GetRequiredService<IMapper>(),
            new AdminContext());
    }

    private static Studio Studio() => new()
    {
        Id = 1,
        Name = "Stay Fit",
        Timezone = "Europe/Zagreb",
        Status = AuthStatuses.Active,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static Trainer Trainer(long id, string email) => new()
    {
        Id = id,
        StudioId = 1,
        FirstName = "Test",
        LastName = "Trainer",
        Email = email,
        Status = AuthStatuses.Active,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private sealed class AdminContext : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { AuthRoles.Admin };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }
}
