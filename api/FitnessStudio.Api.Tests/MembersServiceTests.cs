using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Profiles;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using FitnessStudio.Api.Services.Members;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class MembersServiceTests
{
    [Fact]
    public async Task ListAndGetAreSortedAndScopedToCurrentStudio()
    {
        await using var db = Database();
        db.Members.AddRange(
            Member(1, 1, "Zoe", "Zulu", "zoe@example.com"),
            Member(2, 1, "Ana", "Alpha", "ana@example.com"),
            Member(3, 2, "Foreign", "Member", "foreign@example.com"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var list = await service.GetMembersAsync();
        var local = await service.GetMemberAsync(1);
        var foreign = await service.GetMemberAsync(3);

        Assert.Equal(["Ana", "Zoe"], list.Select(item => item.FirstName));
        Assert.Equal(ServiceResultStatus.Success, local.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task UpdatePersistsMappedFieldsAndNormalizesStatus()
    {
        await using var db = Database();
        db.Members.Add(Member(1, 1, "Old", "Name", "old@example.com"));
        await db.SaveChangesAsync();

        var result = await Service(db).UpdateMemberAsync(1, new UpdateMemberRequest
        {
            FirstName = "Ana",
            LastName = "Horvat",
            Email = "ana@example.com",
            Phone = "+385 91 123",
            DateOfBirth = new DateOnly(1992, 4, 12),
            Status = "PAUSED"
        });

        Assert.Equal(ServiceResultStatus.Success, result.Status);
        var stored = db.Members.Find(1L)!;
        Assert.Equal("Ana", stored.FirstName);
        Assert.Equal("paused", stored.Status);
        Assert.Equal(new DateOnly(1992, 4, 12), stored.DateOfBirth);
    }

    [Fact]
    public async Task UpdateRejectsDuplicateLocalEmailAndHidesForeignId()
    {
        await using var db = Database();
        db.Members.AddRange(
            Member(1, 1, "First", "Member", "first@example.com"),
            Member(2, 1, "Second", "Member", "second@example.com"),
            Member(3, 2, "Foreign", "Member", "foreign@example.com"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var conflict = await service.UpdateMemberAsync(1, Request("second@example.com"));
        var foreign = await service.UpdateMemberAsync(3, Request("changed@example.com"));

        Assert.Equal(ServiceResultStatus.Conflict, conflict.Status);
        Assert.Equal(ServiceResultStatus.NotFound, foreign.Status);
    }

    [Fact]
    public async Task DeleteRemovesMemberAndMissingReturnsNotFound()
    {
        await using var db = Database();
        db.Members.Add(Member(1, 1, "Ana", "Horvat", "ana@example.com"));
        await db.SaveChangesAsync();
        var service = Service(db);

        var removed = await service.DeleteMemberAsync(1);
        var missing = await service.DeleteMemberAsync(99);

        Assert.Equal(ServiceResultStatus.Success, removed.Status);
        Assert.Equal(ServiceResultStatus.NotFound, missing.Status);
        Assert.Empty(db.Members);
    }

    [Fact]
    public async Task DeleteMapsRelatedDataConflict()
    {
        var options = Options();
        await using var db = new DeleteConflictDbContext(options);
        db.Members.Add(Member(1, 1, "Ana", "Horvat", "ana@example.com"));
        await db.SaveChangesAsync();
        db.FailMemberDeletes = true;

        var result = await Service(db).DeleteMemberAsync(1);

        Assert.Equal(ServiceResultStatus.Conflict, result.Status);
    }

    private static DbContextOptions<FitnessStudioDbContext> Options() =>
        new DbContextOptionsBuilder<FitnessStudioDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;

    private static FitnessStudioDbContext Database() => new(Options());

    private static MembersService Service(FitnessStudioDbContext db)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(_ => { }, typeof(MemberProfile).Assembly);
        using var provider = services.BuildServiceProvider();
        return new MembersService(db, provider.GetRequiredService<IMapper>(), new Context());
    }

    private static Member Member(long id, long studioId, string first, string last, string email) => new()
    {
        Id = id,
        StudioId = studioId,
        FirstName = first,
        LastName = last,
        Email = email,
        Status = "active",
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static UpdateMemberRequest Request(string email) => new()
    {
        FirstName = "Updated",
        LastName = "Member",
        Email = email,
        Status = "active"
    };

    private sealed class Context : ICurrentUserContext
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

    private sealed class DeleteConflictDbContext(DbContextOptions<FitnessStudioDbContext> options)
        : FitnessStudioDbContext(options)
    {
        public bool FailMemberDeletes { get; set; }

        public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            if (FailMemberDeletes && ChangeTracker.Entries<Member>()
                    .Any(entry => entry.State == EntityState.Deleted))
            {
                throw new DbUpdateException("Related records exist.");
            }

            return base.SaveChangesAsync(cancellationToken);
        }
    }
}
