using System.Globalization;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.PaymentSettings;

public class PaymentSettingsService : IPaymentSettingsService
{
    private static readonly IReadOnlyDictionary<string, string> Defaults = new Dictionary<string, string>
    {
        ["payment_recipient_name"] = "",
        ["payment_iban"] = "",
        ["payment_model"] = "HR00",
        ["payment_reference"] = "",
        ["payment_description"] = "",
        ["payment_member_reminder_days"] = "0,1",
        ["payment_admin_reminder_days"] = "2",
        ["payment_notification_time"] = "09:00"
    };

    private readonly FitnessStudioDbContext _db;
    private readonly ICurrentUserContext _currentUser;

    public PaymentSettingsService(FitnessStudioDbContext db, ICurrentUserContext currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<PaymentSettingsResponse> GetAsync(long? studioId = null)
    {
        var id = studioId ?? _currentUser.StudioId;
        var stored = await _db.StudioSettings.AsNoTracking()
            .Where(x => x.StudioId == id && Defaults.Keys.Contains(x.Setting))
            .ToDictionaryAsync(x => x.Setting, x => x.Value);
        string Value(string key) => stored.GetValueOrDefault(key, Defaults[key]);

        var recipient = Value("payment_recipient_name");
        var iban = Value("payment_iban");
        var reference = Value("payment_reference");
        var description = Value("payment_description");
        return new PaymentSettingsResponse(
            recipient, iban, Value("payment_model"), reference, description,
            ParseDays(Value("payment_member_reminder_days")),
            ParseDays(Value("payment_admin_reminder_days")),
            TimeOnly.ParseExact(Value("payment_notification_time"), "HH:mm", CultureInfo.InvariantCulture),
            !string.IsNullOrWhiteSpace(recipient) && IsValidIban(iban)
                && !string.IsNullOrWhiteSpace(reference) && !string.IsNullOrWhiteSpace(description));
    }

    public async Task<ServiceResult<PaymentSettingsResponse>> UpdateAsync(UpdatePaymentSettingsRequest request)
    {
        var iban = new string(request.Iban.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        if (!IsValidIban(iban))
            return ServiceResult<PaymentSettingsResponse>.Conflict("Invalid IBAN.", "IBAN control digits are invalid.");
        if (!ValidDays(request.MemberReminderDays) || !ValidDays(request.AdminReminderDays))
            return ServiceResult<PaymentSettingsResponse>.Conflict("Invalid reminder days.", "Reminder offsets must be unique values from 0 to 365.");

        var values = new Dictionary<string, string>
        {
            ["payment_recipient_name"] = request.RecipientName.Trim(),
            ["payment_iban"] = iban,
            ["payment_model"] = request.PaymentModel.Trim().ToUpperInvariant(),
            ["payment_reference"] = request.PaymentReference.Trim(),
            ["payment_description"] = request.PaymentDescription.Trim(),
            ["payment_member_reminder_days"] = string.Join(',', request.MemberReminderDays.Order()),
            ["payment_admin_reminder_days"] = string.Join(',', request.AdminReminderDays.Order()),
            ["payment_notification_time"] = request.NotificationTime.ToString("HH:mm", CultureInfo.InvariantCulture)
        };
        var existing = await _db.StudioSettings.Where(x => x.StudioId == _currentUser.StudioId && values.Keys.Contains(x.Setting)).ToListAsync();
        var now = DateTime.UtcNow;
        foreach (var pair in values)
        {
            var setting = existing.FirstOrDefault(x => x.Setting == pair.Key);
            if (setting is null)
            {
                setting = new StudioSetting { StudioId = _currentUser.StudioId, Setting = pair.Key, ValueType = "string", CreatedAt = now };
                _db.StudioSettings.Add(setting);
            }
            setting.Value = pair.Value;
            setting.UpdatedAt = now;
        }
        await _db.SaveChangesAsync();
        return ServiceResult<PaymentSettingsResponse>.Success(await GetAsync());
    }

    private static IReadOnlyList<int> ParseDays(string value) => value.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(int.Parse).Order().ToArray();
    private static bool ValidDays(IEnumerable<int> days) { var values = days.ToArray(); return values.Length > 0 && values.Distinct().Count() == values.Length && values.All(x => x is >= 0 and <= 365); }
    private static bool IsValidIban(string raw)
    {
        var iban = new string(raw.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        if (iban.Length is < 15 or > 34 || !iban.All(char.IsLetterOrDigit)) return false;
        var rearranged = iban[4..] + iban[..4];
        var remainder = 0;
        foreach (var c in rearranged.SelectMany(c => char.IsLetter(c) ? (c - 'A' + 10).ToString() : c.ToString()))
            remainder = (remainder * 10 + c - '0') % 97;
        return remainder == 1;
    }
}
