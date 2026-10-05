using FitnessStudio.Api.Configuration;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace FitnessStudio.Api.Data;

public static class DevelopmentAuthSeeder
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var options = scope.ServiceProvider
            .GetRequiredService<IOptions<DevelopmentSeedUserOptions>>()
            .Value;

        if (!options.Enabled)
        {
            return;
        }

        var dbContext = scope.ServiceProvider.GetRequiredService<FitnessStudioDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher<AppUser>>();

        foreach (var account in options.Accounts)
        {
            await SeedAccountAsync(dbContext, passwordHasher, account);
        }
    }

    private static async Task SeedAccountAsync(
        FitnessStudioDbContext dbContext,
        IPasswordHasher<AppUser> passwordHasher,
        DevelopmentSeedAccountOptions account)
    {
        if (account.StudioId <= 0)
        {
            throw new InvalidOperationException("Development seed studio id must be positive.");
        }

        var email = account.Email.Trim().ToLowerInvariant();
        var roles = account.Roles
            .Select(role => role.Trim().ToLowerInvariant())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        var allowedRoles = new HashSet<string>([AuthRoles.Admin, AuthRoles.Trainer, AuthRoles.Member]);

        if (roles.Count == 0 || !roles.IsSubsetOf(allowedRoles))
        {
            throw new InvalidOperationException("Development seed roles must contain admin, trainer or member.");
        }

        var memberId = roles.Contains(AuthRoles.Member)
            ? await dbContext.Members
                .Where(member => member.StudioId == account.StudioId && member.Email == email)
                .Select(member => (long?)member.Id)
                .FirstOrDefaultAsync()
            : null;
        var trainerId = roles.Contains(AuthRoles.Trainer)
            ? await dbContext.Trainers
                .Where(trainer => trainer.StudioId == account.StudioId && trainer.Email == email)
                .Select(trainer => (long?)trainer.Id)
                .FirstOrDefaultAsync()
            : null;

        if (roles.Contains(AuthRoles.Member) && memberId is null)
        {
            throw new InvalidOperationException($"Development seed member '{email}' does not exist.");
        }

        if (roles.Contains(AuthRoles.Trainer) && trainerId is null)
        {
            throw new InvalidOperationException($"Development seed trainer '{email}' does not exist.");
        }

        var user = await dbContext.AppUsers
            .Include(existingUser => existingUser.AppUserRoles)
            .FirstOrDefaultAsync(existingUser =>
                existingUser.StudioId == account.StudioId && existingUser.Email == email);
        var now = DateTime.UtcNow;

        if (user is null)
        {
            user = new AppUser
            {
                StudioId = account.StudioId,
                MemberId = memberId,
                TrainerId = trainerId,
                Email = email,
                Status = AuthStatuses.Active,
                CreatedAt = now,
                UpdatedAt = now
            };
            user.PasswordHash = passwordHasher.HashPassword(user, account.Password);
            dbContext.AppUsers.Add(user);
        }

        foreach (var role in roles.Except(user.AppUserRoles.Select(userRole => userRole.Role)))
        {
            user.AppUserRoles.Add(new AppUserRole { Role = role, CreatedAt = now });
        }

        await dbContext.SaveChangesAsync();
    }
}
