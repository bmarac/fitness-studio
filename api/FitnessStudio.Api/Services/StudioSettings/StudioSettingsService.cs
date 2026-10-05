using System.Globalization;
using System.Text.RegularExpressions;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.StudioSettings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.StudioSettings;

public partial class StudioSettingsService : IStudioSettingsService
{
    private static readonly HashSet<string> AllowedValueTypes =
        ["boolean", "integer", "decimal", "string", "enum"];

    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public StudioSettingsService(FitnessStudioDbContext dbContext, ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public Task<List<StudioSettingResponse>> GetSettingsAsync()
    {
        return _dbContext.StudioSettings
            .AsNoTracking()
            .Where(setting => setting.StudioId == _currentUser.StudioId)
            .OrderBy(setting => setting.Setting)
            .Select(setting => new StudioSettingResponse(
                setting.Id,
                setting.Setting,
                setting.Value,
                setting.ValueType))
            .ToListAsync();
    }

    public async Task<ServiceResult<StudioSettingResponse>> GetSettingAsync(string setting)
    {
        var normalizedSetting = NormalizeSetting(setting);
        var response = await _dbContext.StudioSettings
            .AsNoTracking()
            .Where(item =>
                item.StudioId == _currentUser.StudioId && item.Setting == normalizedSetting)
            .Select(item => new StudioSettingResponse(
                item.Id,
                item.Setting,
                item.Value,
                item.ValueType))
            .FirstOrDefaultAsync();

        return response is null
            ? ServiceResult<StudioSettingResponse>.NotFound(
                "Studio setting not found.",
                "A setting with this key does not exist for the current studio.")
            : ServiceResult<StudioSettingResponse>.Success(response);
    }

    public async Task<ServiceResult<StudioSettingResponse>> UpsertSettingAsync(
        string setting,
        UpsertStudioSettingRequest request)
    {
        var normalizedSetting = NormalizeSetting(setting);
        var valueType = request.ValueType.Trim().ToLowerInvariant();
        var value = request.Value.Trim();

        if (!SettingKeyRegex().IsMatch(normalizedSetting))
        {
            return ServiceResult<StudioSettingResponse>.Conflict(
                "Invalid setting key.",
                "Setting keys may contain lowercase letters, numbers, dots, underscores and hyphens.");
        }

        if (!AllowedValueTypes.Contains(valueType) || !IsValidValue(value, valueType))
        {
            return ServiceResult<StudioSettingResponse>.Conflict(
                "Invalid setting value.",
                "The setting value does not match its declared value type.");
        }

        var entity = await _dbContext.StudioSettings.FirstOrDefaultAsync(item =>
            item.StudioId == _currentUser.StudioId && item.Setting == normalizedSetting);
        var now = DateTime.UtcNow;

        if (entity is null)
        {
            entity = new StudioSetting
            {
                StudioId = _currentUser.StudioId,
                Setting = normalizedSetting,
                CreatedAt = now
            };
            _dbContext.StudioSettings.Add(entity);
        }

        entity.Value = value;
        entity.ValueType = valueType;
        entity.UpdatedAt = now;

        await _dbContext.SaveChangesAsync();

        return ServiceResult<StudioSettingResponse>.Success(ToResponse(entity));
    }

    public async Task<ServiceResult> DeleteSettingAsync(string setting)
    {
        var normalizedSetting = NormalizeSetting(setting);
        var entity = await _dbContext.StudioSettings.FirstOrDefaultAsync(item =>
            item.StudioId == _currentUser.StudioId && item.Setting == normalizedSetting);

        if (entity is null)
        {
            return ServiceResult.NotFound(
                "Studio setting not found.",
                "A setting with this key does not exist for the current studio.");
        }

        _dbContext.StudioSettings.Remove(entity);
        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    private static StudioSettingResponse ToResponse(StudioSetting setting)
    {
        return new StudioSettingResponse(setting.Id, setting.Setting, setting.Value, setting.ValueType);
    }

    private static string NormalizeSetting(string setting)
    {
        return setting.Trim().ToLowerInvariant();
    }

    private static bool IsValidValue(string value, string valueType)
    {
        return valueType switch
        {
            "boolean" => bool.TryParse(value, out _),
            "integer" => long.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out _),
            "decimal" => decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out _),
            "string" or "enum" => !string.IsNullOrWhiteSpace(value),
            _ => false
        };
    }

    [GeneratedRegex("^[a-z][a-z0-9_.-]{0,99}$")]
    private static partial Regex SettingKeyRegex();
}
