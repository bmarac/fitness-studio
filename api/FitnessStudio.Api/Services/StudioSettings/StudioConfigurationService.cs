using System.Globalization;
using System.Text.RegularExpressions;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FitnessStudio.Api.Services.StudioSettings;

public partial class StudioConfigurationService : IStudioConfigurationService
{
    private const string JoinCodeKey = "join_code";

    private static readonly IReadOnlyDictionary<string, string> PaymentDefaults =
        new Dictionary<string, string>
        {
            ["payment_recipient_name"] = "",
            ["payment_iban"] = "",
            ["payment_model"] = "HR00",
            ["payment_reference"] = "",
            ["payment_description"] = "",
            ["payment_member_reminder_days"] = "0,1",
            ["payment_admin_reminder_days"] = "2",
            ["payment_notification_time"] = "09:00",
            ["cancellation_cutoff_hours"] = "12"
        };

    private static readonly string[] ManagedKeys =
        [.. PaymentDefaults.Keys, JoinCodeKey];

    private readonly FitnessStudioDbContext _db;
    private readonly ICurrentUserContext _currentUser;

    public StudioConfigurationService(
        FitnessStudioDbContext db,
        ICurrentUserContext currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<StudioConfigurationResponse> GetAsync()
    {
        var stored = await _db.StudioSettings
            .AsNoTracking()
            .Where(setting =>
                setting.StudioId == _currentUser.StudioId
                && ManagedKeys.Contains(setting.Setting))
            .ToDictionaryAsync(setting => setting.Setting, setting => setting.Value);

        return ToResponse(stored);
    }

    public async Task<ServiceResult<StudioConfigurationResponse>> UpdateAsync(
        UpdateStudioConfigurationRequest request)
    {
        var joinCode = request.JoinCode?.Trim().ToUpperInvariant() ?? "";
        var iban = NormalizeIban(request.Iban);

        if (request.JoinByCodeEnabled && !JoinCodeRegex().IsMatch(joinCode))
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Invalid studio code.",
                "The code must contain 3-32 uppercase letters, numbers, '_' or '-'.");
        }

        if (request.JoinByCodeEnabled && await _db.StudioSettings.AnyAsync(setting =>
                setting.Setting == JoinCodeKey
                && setting.StudioId != _currentUser.StudioId
                && setting.Value.ToUpper() == joinCode))
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Studio code already exists.",
                "Choose a different studio code.");
        }

        if (!IsValidIban(iban))
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Invalid IBAN.",
                "IBAN control digits are invalid.");
        }

        if (!ValidDays(request.MemberReminderDays)
            || !ValidDays(request.AdminReminderDays))
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Invalid reminder days.",
                "Reminder offsets must be unique values from 0 to 365.");
        }

        if (request.CancellationCutoffHours is < 0 or > 168)
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Invalid cancellation cutoff.",
                "Cancellation cutoff must be between 0 and 168 hours.");
        }

        var values = new Dictionary<string, string>
        {
            ["payment_recipient_name"] = request.RecipientName.Trim(),
            ["payment_iban"] = iban,
            ["payment_model"] = request.PaymentModel.Trim().ToUpperInvariant(),
            ["payment_reference"] = request.PaymentReference.Trim(),
            ["payment_description"] = request.PaymentDescription.Trim(),
            ["payment_member_reminder_days"] = string.Join(
                ',', request.MemberReminderDays.Order()),
            ["payment_admin_reminder_days"] = string.Join(
                ',', request.AdminReminderDays.Order()),
            ["payment_notification_time"] = request.NotificationTime.ToString(
                "HH:mm", CultureInfo.InvariantCulture),
            ["cancellation_cutoff_hours"] = request.CancellationCutoffHours.ToString(
                CultureInfo.InvariantCulture)
        };

        var managedKeys = values.Keys.Append(JoinCodeKey).ToArray();
        var existing = await _db.StudioSettings
            .Where(setting =>
                setting.StudioId == _currentUser.StudioId
                && managedKeys.Contains(setting.Setting))
            .ToListAsync();
        var now = DateTime.UtcNow;

        foreach (var pair in values)
        {
            Upsert(
                existing,
                pair.Key,
                pair.Value,
                now,
                pair.Key == "cancellation_cutoff_hours" ? "integer" : "string");
        }

        var existingJoinCode = existing.FirstOrDefault(
            setting => setting.Setting == JoinCodeKey);
        if (request.JoinByCodeEnabled)
        {
            Upsert(existing, JoinCodeKey, joinCode, now);
        }
        else if (existingJoinCode is not null)
        {
            _db.StudioSettings.Remove(existingJoinCode);
        }

        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException exception)
            when (exception.InnerException is PostgresException
                { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            return ServiceResult<StudioConfigurationResponse>.Conflict(
                "Studio code already exists.",
                "Choose a different studio code.");
        }

        var stored = values.ToDictionary(pair => pair.Key, pair => pair.Value);
        if (request.JoinByCodeEnabled)
        {
            stored[JoinCodeKey] = joinCode;
        }

        return ServiceResult<StudioConfigurationResponse>.Success(ToResponse(stored));
    }

    private void Upsert(
        IReadOnlyCollection<StudioSetting> existing,
        string key,
        string value,
        DateTime now,
        string valueType = "string")
    {
        var setting = existing.FirstOrDefault(item => item.Setting == key);
        if (setting is null)
        {
            setting = new StudioSetting
            {
                StudioId = _currentUser.StudioId,
                Setting = key,
                ValueType = valueType,
                CreatedAt = now
            };
            _db.StudioSettings.Add(setting);
        }

        setting.Value = value;
        setting.ValueType = valueType;
        setting.UpdatedAt = now;
    }

    private static StudioConfigurationResponse ToResponse(
        IReadOnlyDictionary<string, string> stored)
    {
        string Value(string key) => stored.GetValueOrDefault(key, PaymentDefaults[key]);

        var joinCode = stored.GetValueOrDefault(JoinCodeKey);
        var recipient = Value("payment_recipient_name");
        var iban = Value("payment_iban");
        var reference = Value("payment_reference");
        var description = Value("payment_description");

        return new StudioConfigurationResponse(
            joinCode is not null,
            joinCode,
            recipient,
            iban,
            Value("payment_model"),
            reference,
            description,
            ParseDays(Value("payment_member_reminder_days")),
            ParseDays(Value("payment_admin_reminder_days")),
            TimeOnly.ParseExact(
                Value("payment_notification_time"),
                "HH:mm",
                CultureInfo.InvariantCulture),
            ParseCancellationCutoff(Value("cancellation_cutoff_hours")),
            !string.IsNullOrWhiteSpace(recipient)
                && IsValidIban(iban)
                && !string.IsNullOrWhiteSpace(reference)
                && !string.IsNullOrWhiteSpace(description));
    }

    private static IReadOnlyList<int> ParseDays(string value) => value
        .Split(',', StringSplitOptions.RemoveEmptyEntries)
        .Select(int.Parse)
        .Order()
        .ToArray();

    private static int ParseCancellationCutoff(string value) =>
        int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var hours)
            && hours is >= 0 and <= 168
                ? hours
                : 12;

    private static bool ValidDays(IEnumerable<int> days)
    {
        var values = days.ToArray();
        return values.Length > 0
            && values.Distinct().Count() == values.Length
            && values.All(value => value is >= 0 and <= 365);
    }

    private static string NormalizeIban(string raw) =>
        new string(raw.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();

    private static bool IsValidIban(string raw)
    {
        var iban = NormalizeIban(raw);
        if (iban.Length is < 15 or > 34 || !iban.All(char.IsLetterOrDigit))
        {
            return false;
        }

        var rearranged = iban[4..] + iban[..4];
        var remainder = 0;
        foreach (var character in rearranged.SelectMany(character =>
                     char.IsLetter(character)
                         ? (character - 'A' + 10).ToString()
                         : character.ToString()))
        {
            remainder = (remainder * 10 + character - '0') % 97;
        }

        return remainder == 1;
    }

    [GeneratedRegex("^[A-Z0-9][A-Z0-9_-]{2,31}$")]
    private static partial Regex JoinCodeRegex();
}
