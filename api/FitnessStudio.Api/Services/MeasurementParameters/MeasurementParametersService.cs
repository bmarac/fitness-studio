using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MeasurementParameters;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MeasurementParameters;

public class MeasurementParametersService : IMeasurementParametersService
{
    private static readonly HashSet<string> AllowedValueTypes = ["decimal", "integer"];
    private static readonly HashSet<string> AllowedSources = ["manual", "calculated"];
    private static readonly HashSet<string> AllowedCalculationTypes = ["bmi"];
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
        var validationResult = ValidateDefinition(
            request.ValueType,
            request.Source,
            request.CalculationType,
            request.MinValue,
            request.MaxValue,
            request.DecimalPlaces,
            request.Status);
        if (validationResult is not null)
        {
            return ToTypedFailure(validationResult);
        }

        var code = Normalize(request.Code);
        if (await QueryParameters().AnyAsync(parameter => parameter.Code == code))
        {
            return ServiceResult<MeasurementParameterResponse>.Conflict(
                "Measurement parameter code already exists.",
                "A parameter with this code already exists in the current studio.");
        }

        var now = DateTime.UtcNow;
        var parameter = new MeasurementParameter
        {
            StudioId = _currentUser.StudioId,
            Code = code,
            Name = request.Name.Trim(),
            Unit = NormalizeOptionalText(request.Unit),
            ValueType = Normalize(request.ValueType),
            Source = Normalize(request.Source),
            CalculationType = NormalizeOptional(request.CalculationType),
            MinValue = request.MinValue,
            MaxValue = request.MaxValue,
            DecimalPlaces = request.DecimalPlaces,
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

        var validationResult = ValidateDefinition(
            request.ValueType,
            request.Source,
            request.CalculationType,
            request.MinValue,
            request.MaxValue,
            request.DecimalPlaces,
            request.Status);
        if (validationResult is not null)
        {
            return validationResult;
        }

        var valueType = Normalize(request.ValueType);
        var source = Normalize(request.Source);
        var calculationType = NormalizeOptional(request.CalculationType);
        var definitionChanged = parameter.ValueType != valueType
            || parameter.Source != source
            || parameter.CalculationType != calculationType;

        if (definitionChanged && await _dbContext.MemberMeasurementValues
                .AnyAsync(value => value.ParameterId == parameter.Id))
        {
            return ServiceResult.Conflict(
                "Measurement parameter definition cannot be changed.",
                "Value type, source and calculation type cannot change after values have been recorded.");
        }

        parameter.Name = request.Name.Trim();
        parameter.Unit = NormalizeOptionalText(request.Unit);
        parameter.ValueType = valueType;
        parameter.Source = source;
        parameter.CalculationType = calculationType;
        parameter.MinValue = request.MinValue;
        parameter.MaxValue = request.MaxValue;
        parameter.DecimalPlaces = request.DecimalPlaces;
        parameter.SortOrder = request.SortOrder;
        parameter.Status = Normalize(request.Status);
        parameter.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
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
            parameter.ValueType,
            parameter.Source,
            parameter.CalculationType,
            parameter.MinValue,
            parameter.MaxValue,
            parameter.DecimalPlaces,
            parameter.SortOrder,
            parameter.Status));
    }

    private static ServiceResult? ValidateDefinition(
        string requestedValueType,
        string requestedSource,
        string? requestedCalculationType,
        decimal? minValue,
        decimal? maxValue,
        short decimalPlaces,
        string requestedStatus)
    {
        var valueType = Normalize(requestedValueType);
        var source = Normalize(requestedSource);
        var calculationType = NormalizeOptional(requestedCalculationType);
        var status = Normalize(requestedStatus);

        if (!AllowedValueTypes.Contains(valueType))
        {
            return ServiceResult.Conflict(
                "Invalid measurement value type.",
                "Value type must be decimal or integer.");
        }

        if (!AllowedSources.Contains(source))
        {
            return ServiceResult.Conflict(
                "Invalid measurement source.",
                "Source must be manual or calculated.");
        }

        if ((source == "manual" && calculationType is not null)
            || (source == "calculated"
                && (calculationType is null || !AllowedCalculationTypes.Contains(calculationType))))
        {
            return ServiceResult.Conflict(
                "Invalid measurement calculation.",
                "Manual parameters cannot have a calculation; calculated parameters currently support only bmi.");
        }

        if (!AllowedStatuses.Contains(status))
        {
            return ServiceResult.Conflict(
                "Invalid measurement parameter status.",
                "Status must be active or inactive.");
        }

        if (minValue.HasValue
            && maxValue.HasValue
            && minValue.Value > maxValue.Value)
        {
            return ServiceResult.Conflict(
                "Invalid measurement range.",
                "Minimum value cannot be greater than maximum value.");
        }

        if (valueType == "integer" && decimalPlaces != 0)
        {
            return ServiceResult.Conflict(
                "Invalid decimal places.",
                "Integer parameters must use zero decimal places.");
        }

        return null;
    }

    private static string Normalize(string value) => value.Trim().ToLowerInvariant();

    private static string? NormalizeOptional(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : Normalize(value);

    private static string? NormalizeOptionalText(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static MeasurementParameterResponse ToResponse(MeasurementParameter parameter)
    {
        return new MeasurementParameterResponse(
            parameter.Id,
            parameter.Code,
            parameter.Name,
            parameter.Unit,
            parameter.ValueType,
            parameter.Source,
            parameter.CalculationType,
            parameter.MinValue,
            parameter.MaxValue,
            parameter.DecimalPlaces,
            parameter.SortOrder,
            parameter.Status);
    }

    private static ServiceResult<MeasurementParameterResponse> ToTypedFailure(ServiceResult result)
    {
        return new ServiceResult<MeasurementParameterResponse>(result.Status, default, result.Error);
    }
}
