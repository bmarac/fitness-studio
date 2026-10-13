using System.Text.RegularExpressions;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Data;

public static partial class StudioProvisioningCommand
{
    public static async Task RunAsync(IServiceProvider services, string[] args)
    {
        var values = ParseArguments(args.Skip(1).ToArray());
        var required = new[] { "name", "code", "timezone", "email" };
        var missing = required.Where(key => !values.ContainsKey(key)).ToArray();
        if (missing.Length > 0)
        {
            throw new InvalidOperationException($"Missing options: {string.Join(", ", missing.Select(x => "--" + x))}.");
        }

        var password = Environment.GetEnvironmentVariable("FITNESS_STUDIO_ADMIN_PASSWORD");
        if (string.IsNullOrWhiteSpace(password) || password.Length < 10)
        {
            throw new InvalidOperationException(
                "FITNESS_STUDIO_ADMIN_PASSWORD must contain at least 10 characters.");
        }

        var code = values["code"].Trim().ToUpperInvariant();
        var email = values["email"].Trim().ToLowerInvariant();
        var timezone = values["timezone"].Trim();
        if (!PublicCodeRegex().IsMatch(code))
        {
            throw new InvalidOperationException("Studio code must contain 3-32 uppercase letters, numbers, '_' or '-'.");
        }
        _ = TimeZoneInfo.FindSystemTimeZoneById(timezone);

        await using var scope = services.CreateAsyncScope();
        var db = scope.ServiceProvider.GetRequiredService<FitnessStudioDbContext>();
        var hasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher<AppUser>>();
        if (await db.StudioSettings.AnyAsync(setting =>
                setting.Setting == "join_code" && setting.Value.ToUpper() == code))
        {
            throw new InvalidOperationException($"Studio code '{code}' already exists.");
        }

        await using var transaction = await db.Database.BeginTransactionAsync();
        var now = DateTime.UtcNow;
        var studio = new Studio
        {
            Name = values["name"].Trim(),
            Timezone = timezone,
            Status = AuthStatuses.Active,
            CreatedAt = now,
            UpdatedAt = now
        };
        db.Studios.Add(studio);
        await db.SaveChangesAsync();

        db.StudioSettings.Add(new StudioSetting
        {
            StudioId = studio.Id,
            Setting = "join_code",
            Value = code,
            ValueType = "string",
            CreatedAt = now,
            UpdatedAt = now
        });

        var admin = await db.AppUsers
            .Include(user => user.StudioMemberships)
            .FirstOrDefaultAsync(user => user.Email == email);
        if (admin is null)
        {
            admin = new AppUser
            {
                Email = email,
                PasswordHash = string.Empty,
                Status = AuthStatuses.Active,
                CreatedAt = now,
                UpdatedAt = now
            };
            admin.PasswordHash = hasher.HashPassword(admin, password);
            db.AppUsers.Add(admin);
        }
        var membership = new AppUserStudio
        {
            Studio = studio,
            Status = AuthStatuses.Active,
            JoinedAt = now,
            UpdatedAt = now
        };
        membership.Roles.Add(new AppUserRole { Role = AuthRoles.Admin, CreatedAt = now });
        admin.StudioMemberships.Add(membership);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();

        Console.WriteLine($"Provisioned studio '{studio.Name}' ({code}) and admin '{admin.Email}'.");
    }

    private static Dictionary<string, string> ParseArguments(string[] args)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (var index = 0; index < args.Length; index += 2)
        {
            if (!args[index].StartsWith("--", StringComparison.Ordinal) || index + 1 >= args.Length)
            {
                throw new InvalidOperationException("Provisioning options must use '--name value' format.");
            }
            result[args[index][2..]] = args[index + 1];
        }
        return result;
    }

    [GeneratedRegex("^[A-Z0-9][A-Z0-9_-]{2,31}$")]
    private static partial Regex PublicCodeRegex();
}
