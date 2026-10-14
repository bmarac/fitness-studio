using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.ClassTypes;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Profiles;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.ClassTypes;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class ClassTypesServiceTests
{
    [Fact]
    public async Task ListAndGetAreSortedAndScopedToCurrentStudio()
    {
        await using var db = Database();
        db.ClassTypes.AddRange(
            ClassType(1, 1, "Yoga"),
            ClassType(2, 1, "Pilates"),
            ClassType(3, 2, "Foreign"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var list = await service.GetClassTypesAsync();
        var local = await service.GetClassTypeAsync(1);
        var foreign = await service.GetClassTypeAsync(3);

        Assert.Equal(["Pilates", "Yoga"], list.Select(item => item.Name));
        Assert.Equal(ServiceResultStatus.Success, local.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task CreateAssignsStudioAndNormalizesEnumeratedValues()
    {
        await using var db = Database();
        var service = Service(db);

        var result = await service.CreateClassTypeAsync(Create("Pilates", "BEGINNER", "ACTIVE"));

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var stored = Assert.Single(db.ClassTypes);
        Assert.Equal(1, stored.StudioId);
        Assert.Equal("beginner", stored.DifficultyLevel);
        Assert.Equal("active", stored.Status);
        Assert.NotEqual(default, stored.CreatedAt);
        Assert.Equal(stored.CreatedAt, stored.UpdatedAt);
    }

    [Fact]
    public async Task CreateRejectsDuplicateNameOnlyInsideCurrentStudio()
    {
        await using var db = Database();
        db.ClassTypes.AddRange(ClassType(1, 1, "Pilates"), ClassType(2, 2, "Yoga"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var duplicate = await service.CreateClassTypeAsync(Create("Pilates"));
        var otherStudioName = await service.CreateClassTypeAsync(Create("Yoga"));

        Assert.Equal(ServiceResultStatus.Conflict, duplicate.Status);
        Assert.Equal(ServiceResultStatus.Success, otherStudioName.Status);
    }

    [Fact]
    public async Task UpdatePersistsFieldsAndRejectsAnotherLocalName()
    {
        await using var db = Database();
        db.ClassTypes.AddRange(ClassType(1, 1, "Pilates"), ClassType(2, 1, "Yoga"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var conflict = await service.UpdateClassTypeAsync(1, Update("Yoga"));
        var updated = await service.UpdateClassTypeAsync(1, Update("Strength", "ADVANCED", "INACTIVE"));

        Assert.Equal(ServiceResultStatus.Conflict, conflict.Status);
        Assert.Equal(ServiceResultStatus.Success, updated.Status);
        var stored = db.ClassTypes.Find(1L)!;
        Assert.Equal("Strength", stored.Name);
        Assert.Equal("advanced", stored.DifficultyLevel);
        Assert.Equal("inactive", stored.Status);
        Assert.Equal(75, stored.DefaultDurationMinutes);
        Assert.Equal(12, stored.DefaultCapacity);
    }

    [Fact]
    public async Task UpdateAndDeleteHideForeignOrMissingIds()
    {
        await using var db = Database();
        db.ClassTypes.Add(ClassType(2, 2, "Foreign"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var update = await service.UpdateClassTypeAsync(2, Update("Changed"));
        var delete = await service.DeleteClassTypeAsync(99);

        Assert.Equal(ServiceResultStatus.NotFound, update.Status);
        Assert.Equal(ServiceResultStatus.NotFound, delete.Status);
        Assert.Single(db.ClassTypes);
    }

    [Fact]
    public async Task DeleteRemovesUnreferencedClassType()
    {
        await using var db = Database();
        db.ClassTypes.Add(ClassType(1, 1, "Pilates"));
        await db.SaveChangesAsync();

        var result = await Service(db).DeleteClassTypeAsync(1);

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Empty(db.ClassTypes);
    }

    [Fact]
    public async Task DeleteReturnsConflictWhenRelatedDataPreventsRemoval()
    {
        var options = new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        await using var db = new DeleteConflictDbContext(options);
        db.ClassTypes.Add(ClassType(1, 1, "Pilates"));
        await db.SaveChangesAsync();
        db.FailDeletes = true;

        var result = await Service(db).DeleteClassTypeAsync(1);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
    }

    [Fact]
    public async Task BulkConfigurationUpdatesAddsAndDeletesInOneSave()
    {
        await using var db = Database();
        db.ClassTypes.AddRange(ClassType(1, 1, "Pilates"), ClassType(2, 1, "Yoga"));
        await db.SaveChangesAsync();

        var result = await Service(db).SaveConfigurationAsync(new SaveClassTypesConfigurationRequest
        {
            Items =
            [
                new ClassTypeConfigurationItemRequest
                {
                    Id = 1,
                    Name = "Power Pilates",
                    DefaultDurationMinutes = 75,
                    DefaultCapacity = 12,
                    DifficultyLevel = "advanced",
                    Status = "inactive"
                },
                new ClassTypeConfigurationItemRequest
                {
                    Name = "Mobility",
                    DefaultDurationMinutes = 45,
                    DefaultCapacity = 8,
                    DifficultyLevel = "all_levels",
                    Status = "active"
                }
            ],
            DeletedIds = [2]
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        Assert.Equal(["Mobility", "Power Pilates"], result.Value!.Select(item => item.Name));
        Assert.DoesNotContain(db.ClassTypes, item => item.Id == 2);
        Assert.Equal("inactive", db.ClassTypes.Single(item => item.Name == "Power Pilates").Status);
    }

    [Fact]
    public async Task BulkConfigurationRejectsDuplicatesWithoutChangingStoredData()
    {
        await using var db = Database();
        db.ClassTypes.Add(ClassType(1, 1, "Pilates"));
        await db.SaveChangesAsync();

        var result = await Service(db).SaveConfigurationAsync(new SaveClassTypesConfigurationRequest
        {
            Items =
            [
                ConfigurationItem(1, "Duplicate"),
                ConfigurationItem(null, "duplicate")
            ]
        });

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
        Assert.Equal("Pilates", db.ClassTypes.Single().Name);
    }

    private static FitnessStudioDbContext Database() => new(
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static ClassTypesService Service(FitnessStudioDbContext db)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(_ => { }, typeof(ClassTypeProfile).Assembly);
        using var provider = services.BuildServiceProvider();
        return new ClassTypesService(db, provider.GetRequiredService<IMapper>(), new Context());
    }

    private static ClassType ClassType(long id, long studioId, string name) => new()
    {
        Id = id,
        StudioId = studioId,
        Name = name,
        DefaultDurationMinutes = 60,
        DefaultCapacity = 10,
        DifficultyLevel = "all_levels",
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static CreateClassTypeRequest Create(
        string name,
        string difficulty = "all_levels",
        string status = "active") => new()
        {
            Name = name,
            Description = "Description",
            DefaultDurationMinutes = 60,
            DefaultCapacity = 10,
            DifficultyLevel = difficulty,
            Status = status
        };

    private static UpdateClassTypeRequest Update(
        string name,
        string difficulty = "all_levels",
        string status = "active") => new()
        {
            Name = name,
            Description = "Updated",
            DefaultDurationMinutes = 75,
            DefaultCapacity = 12,
            DifficultyLevel = difficulty,
            Status = status
        };

    private static ClassTypeConfigurationItemRequest ConfigurationItem(long? id, string name) => new()
    {
        Id = id,
        Name = name,
        DefaultDurationMinutes = 60,
        DefaultCapacity = 10,
        DifficultyLevel = "all_levels",
        Status = "active"
    };

    private sealed class Context : ICurrentUserContext
    {
        public long UserId => 1;
        public string Email => "admin@example.com";
        public long StudioId => 1;
        public long? MemberId => null;
        public long? TrainerId => null;
        public IReadOnlySet<string> Roles { get; } = new HashSet<string> { "admin" };
        public bool IsMemberOnly => false;
        public bool IsInRole(string role) => Roles.Contains(role);
    }

    private sealed class DeleteConflictDbContext(DbContextOptions<FitnessStudioDbContext> options)
        : FitnessStudioDbContext(options)
    {
        public bool FailDeletes { get; set; }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            if (FailDeletes && ChangeTracker.Entries<ClassType>()
                    .Any(entry => entry.State == EntityState.Deleted))
            {
                throw new DbUpdateException("Related sessions exist.");
            }

            return base.SaveChangesAsync(cancellationToken);
        }
    }
}
