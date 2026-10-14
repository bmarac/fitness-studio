using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MeasurementParameters;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using System.Text;

namespace FitnessStudio.Api.Services.MeasurementParameters;

public class MeasurementParametersService : IMeasurementParametersService
{
    private static readonly HashSet<string> AllowedStatuses = ["active", "inactive"];

    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MeasurementParametersService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public Task<List<MeasurementParameterResponse>> GetParametersAsync()
    {
        var query = QueryParameters();

        if (!_currentUser.IsInRole(AuthRoles.Admin))
        {
            query = query.Where(parameter => parameter.Status == "active");
        }

        return Project(query
                .OrderBy(parameter => parameter.SortOrder)
                .ThenBy(parameter => parameter.Name))
            .ToListAsync();
    }

    public async Task<ServiceResult<MeasurementParameterResponse>> GetParameterAsync(long id)
    {
        var query = QueryParameters().Where(parameter => parameter.Id == id);

        if (!_currentUser.IsInRole(AuthRoles.Admin))
        {
            query = query.Where(parameter => parameter.Status == "active");
        }

        var parameter = await Project(query).FirstOrDefaultAsync();

        return parameter is null
            ? ServiceResult<MeasurementParameterResponse>.NotFound(
                "Measurement parameter not found.",
                "A measurement parameter with this id does not exist.")
            : ServiceResult<MeasurementParameterResponse>.Success(parameter);
    }

    public async Task<ServiceResult<MeasurementParameterResponse>> CreateParameterAsync(
        CreateMeasurementParameterRequest request)
    {
        var validationResult = ValidateStatus(request.Status);
        if (validationResult is not null)
        {
            return ToTypedFailure(validationResult);
        }

        var usedCodes = await QueryParameters().Select(parameter => parameter.Code).ToListAsync();
        var code = GenerateUniqueCode(request.Name, usedCodes);

        var now = DateTime.UtcNow;
        var parameter = new MeasurementParameter
        {
            StudioId = _currentUser.StudioId,
            Code = code,
            Name = request.Name.Trim(),
            Unit = NormalizeOptionalText(request.Unit),
            SortOrder = request.SortOrder,
            Status = Normalize(request.Status),
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.MeasurementParameters.Add(parameter);
        await _dbContext.SaveChangesAsync();

        return ServiceResult<MeasurementParameterResponse>.Success(ToResponse(parameter));
    }

    public async Task<ServiceResult> UpdateParameterAsync(
        long id,
        UpdateMeasurementParameterRequest request)
    {
        var parameter = await QueryParameters().FirstOrDefaultAsync(item => item.Id == id);
        if (parameter is null)
        {
            return ServiceResult.NotFound(
                "Measurement parameter not found.",
                "A measurement parameter with this id does not exist.");
        }

        var validationResult = ValidateStatus(request.Status);
        if (validationResult is not null)
        {
            return validationResult;
        }

        parameter.Name = request.Name.Trim();
        parameter.Unit = NormalizeOptionalText(request.Unit);
        parameter.SortOrder = request.SortOrder;
        parameter.Status = Normalize(request.Status);
        parameter.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    public async Task<ServiceResult<List<MeasurementParameterResponse>>> SaveConfigurationAsync(
        SaveMeasurementParametersConfigurationRequest request)
    {
        var ids = request.Items.Where(item => item.Id.HasValue)
            .Select(item => item.Id!.Value).ToList();
        if (ids.Count != ids.Distinct().Count())
        {
            return ServiceResult<List<MeasurementParameterResponse>>.Conflict(
                "Invalid measurement parameter configuration.",
                "A parameter can appear only once in the configuration.");
        }

        foreach (var item in request.Items)
        {
            var validation = ValidateStatus(item.Status);
            if (validation is not null)
            {
                return new ServiceResult<List<MeasurementParameterResponse>>(
                    validation.Status,
                    default,
                    validation.Error);
            }
        }

        var existing = await QueryParameters().Where(item => ids.Contains(item.Id))
            .ToDictionaryAsync(item => item.Id);
        if (existing.Count != ids.Count)
        {
            return ServiceResult<List<MeasurementParameterResponse>>.NotFound(
                "Measurement parameter not found.",
                "Every parameter must belong to the current studio.");
        }

        var now = DateTime.UtcNow;
        var usedCodes = (await QueryParameters().Select(parameter => parameter.Code).ToListAsync())
            .ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var item in request.Items)
        {
            var parameter = item.Id.HasValue ? existing[item.Id.Value] : new MeasurementParameter
            {
                StudioId = _currentUser.StudioId,
                Code = GenerateUniqueCode(item.Name, usedCodes),
                CreatedAt = now
            };
            parameter.Name = item.Name.Trim();
            parameter.Unit = NormalizeOptionalText(item.Unit);
            parameter.SortOrder = item.SortOrder;
            parameter.Status = Normalize(item.Status);
            parameter.UpdatedAt = now;
            if (!item.Id.HasValue) _dbContext.MeasurementParameters.Add(parameter);
        }

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult<List<MeasurementParameterResponse>>.Conflict(
                "Measurement parameter configuration cannot be saved.",
                "Parameter codes must be unique in the current studio.");
        }

        return ServiceResult<List<MeasurementParameterResponse>>.Success(
            await GetParametersAsync());
    }

    public async Task<ServiceResult> DeleteParameterAsync(long id)
    {
        var parameter = await QueryParameters().FirstOrDefaultAsync(item => item.Id == id);
        if (parameter is null)
        {
            return ServiceResult.NotFound(
                "Measurement parameter not found.",
                "A measurement parameter with this id does not exist.");
        }

        parameter.Status = "inactive";
        parameter.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    private IQueryable<MeasurementParameter> QueryParameters()
    {
        return _dbContext.MeasurementParameters
            .Where(parameter => parameter.StudioId == _currentUser.StudioId);
    }

    private static IQueryable<MeasurementParameterResponse> Project(
        IQueryable<MeasurementParameter> query)
    {
        return query.AsNoTracking().Select(parameter => new MeasurementParameterResponse(
            parameter.Id,
            parameter.Code,
            parameter.Name,
            parameter.Unit,
            parameter.SortOrder,
            parameter.Status));
    }

    private static ServiceResult? ValidateStatus(string requestedStatus)
    {
        var status = Normalize(requestedStatus);

        if (!AllowedStatuses.Contains(status))
        {
            return ServiceResult.Conflict(
                "Invalid measurement parameter status.",
                "Status must be active or inactive.");
        }

        return null;
    }

    private static string GenerateUniqueCode(string name, IEnumerable<string> existingCodes)
    {
        var usedCodes = existingCodes as ISet<string>
            ?? existingCodes.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var baseCode = Slugify(name);
        var code = baseCode;
        for (var suffix = 2; usedCodes.Contains(code); suffix++)
        {
            var suffixText = $"_{suffix}";
            code = $"{baseCode[..Math.Min(baseCode.Length, 80 - suffixText.Length)]}{suffixText}";
        }

        usedCodes.Add(code);
        return code;
    }

    private static string Slugify(string value)
    {
        var normalized = value.Trim().Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder();
        var separatorPending = false;
        foreach (var character in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(character) == UnicodeCategory.NonSpacingMark)
            {
                continue;
            }

            if (character <= 127 && char.IsLetterOrDigit(character))
            {
                if (separatorPending && builder.Length > 0) builder.Append('_');
                builder.Append(char.ToLowerInvariant(character));
                separatorPending = false;
            }
            else
            {
                separatorPending = builder.Length > 0;
            }
        }

        var code = builder.ToString();
        if (code.Length == 0) code = "parametar";
        if (!char.IsLetter(code[0])) code = $"parametar_{code}";
        return code[..Math.Min(code.Length, 80)];
    }

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();

    private static string? NormalizeOptionalText(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static MeasurementParameterResponse ToResponse(MeasurementParameter parameter)
    {
        return new MeasurementParameterResponse(
            parameter.Id,
            parameter.Code,
            parameter.Name,
            parameter.Unit,
            parameter.SortOrder,
            parameter.Status);
    }

    private static ServiceResult<MeasurementParameterResponse> ToTypedFailure(ServiceResult result)
    {
        return new ServiceResult<MeasurementParameterResponse>(result.Status, default, result.Error);
    }
}
