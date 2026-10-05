using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.MemberMeasurements;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.MemberMeasurements;

public class MemberMeasurementsService : IMemberMeasurementsService
{
    private const string HeightCode = "height_cm";
    private const string WeightCode = "weight_kg";

    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public MemberMeasurementsService(
        FitnessStudioDbContext dbContext,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<ServiceResult<List<MemberMeasurementResponse>>> GetMeasurementsAsync(long memberId)
    {
        var accessResult = await ValidateMemberAccessAsync(memberId, writeAccess: false);
        if (accessResult is not null)
        {
            return ToTypedFailure<List<MemberMeasurementResponse>>(accessResult);
        }

        var measurements = await LoadMeasurementsAsync(memberId);
        var calculatedParameters = await LoadCalculatedParametersAsync();
        var responses = BuildHistory(measurements, calculatedParameters)
            .OrderByDescending(measurement => measurement.MeasuredAt)
            .ToList();

        return ServiceResult<List<MemberMeasurementResponse>>.Success(responses);
    }

    public async Task<ServiceResult<MemberLatestMeasurementsResponse>> GetLatestMeasurementsAsync(
        long memberId)
    {
        var accessResult = await ValidateMemberAccessAsync(memberId, writeAccess: false);
        if (accessResult is not null)
        {
            return ToTypedFailure<MemberLatestMeasurementsResponse>(accessResult);
        }

        var measurements = await LoadMeasurementsAsync(memberId);
        var values = measurements
            .SelectMany(measurement => measurement.MemberMeasurementValues.Select(value => new
            {
                Value = value,
                measurement.MeasuredAt
            }))
            .GroupBy(item => item.Value.ParameterId)
            .Select(group => group.OrderByDescending(item => item.MeasuredAt).First())
            .Select(item => new MemberLatestMeasurementValueResponse(
                item.Value.ParameterId,
                item.Value.Parameter.Code,
                item.Value.Parameter.Name,
                item.Value.Parameter.Unit,
                item.Value.NumericValue,
                item.Value.Parameter.DecimalPlaces,
                item.Value.Parameter.SortOrder,
                item.Value.Parameter.Source,
                item.MeasuredAt))
            .ToList();

        var calculatedParameters = await LoadCalculatedParametersAsync();
        AddLatestCalculatedValues(values, calculatedParameters);

        return ServiceResult<MemberLatestMeasurementsResponse>.Success(
            new MemberLatestMeasurementsResponse(
                memberId,
                values.OrderBy(value => value.SortOrder)
                    .ThenBy(value => value.Name)
                    .ToList()));
    }

    public async Task<ServiceResult<MemberMeasurementResponse>> CreateMeasurementAsync(
        long memberId,
        CreateMemberMeasurementRequest request)
    {
        var accessResult = await ValidateMemberAccessAsync(memberId, writeAccess: true);
        if (accessResult is not null)
        {
            return ToTypedFailure<MemberMeasurementResponse>(accessResult);
        }

        if (request.MeasuredAt == default)
        {
            return ServiceResult<MemberMeasurementResponse>.Conflict(
                "Invalid measurement time.",
                "Measurement time is required.");
        }

        var measuredAt = request.MeasuredAt.ToUniversalTime();
        if (measuredAt > DateTime.UtcNow.AddMinutes(5))
        {
            return ServiceResult<MemberMeasurementResponse>.Conflict(
                "Invalid measurement time.",
                "Measurement time cannot be in the future.");
        }

        var duplicateParameterId = request.Values
            .GroupBy(value => value.ParameterId)
            .FirstOrDefault(group => group.Count() > 1)
            ?.Key;
        if (duplicateParameterId.HasValue)
        {
            return ServiceResult<MemberMeasurementResponse>.Conflict(
                "Duplicate measurement parameter.",
                "Each parameter can be supplied only once per measurement.");
        }

        var parameterIds = request.Values.Select(value => value.ParameterId).ToList();
        var parameters = await _dbContext.MeasurementParameters
            .Where(parameter =>
                parameter.StudioId == _currentUser.StudioId
                && parameterIds.Contains(parameter.Id))
            .ToDictionaryAsync(parameter => parameter.Id);

        if (parameters.Count != parameterIds.Count)
        {
            return ServiceResult<MemberMeasurementResponse>.Conflict(
                "Measurement parameter does not exist.",
                "Every value must reference a parameter from the current studio.");
        }

        foreach (var requestedValue in request.Values)
        {
            var parameter = parameters[requestedValue.ParameterId];
            var valueValidation = ValidateValue(parameter, requestedValue.Value);
            if (valueValidation is not null)
            {
                return ToTypedFailure<MemberMeasurementResponse>(valueValidation);
            }
        }

        var now = DateTime.UtcNow;
        var measurement = new MemberMeasurement
        {
            StudioId = _currentUser.StudioId,
            MemberId = memberId,
            MeasuredAt = measuredAt,
            RecordedByUserId = _currentUser.UserId,
            Note = string.IsNullOrWhiteSpace(request.Note) ? null : request.Note.Trim(),
            CreatedAt = now,
            UpdatedAt = now,
            MemberMeasurementValues = request.Values.Select(requestedValue =>
                new MemberMeasurementValue
                {
                    ParameterId = requestedValue.ParameterId,
                    NumericValue = requestedValue.Value,
                    CreatedAt = now,
                    UpdatedAt = now
                }).ToList()
        };

        _dbContext.MemberMeasurements.Add(measurement);
        await _dbContext.SaveChangesAsync();

        foreach (var value in measurement.MemberMeasurementValues)
        {
            value.Parameter = parameters[value.ParameterId];
        }

        var response = ToResponse(measurement);
        var calculatedParameters = await LoadCalculatedParametersAsync();
        var latest = await GetLatestManualValuesAtAsync(memberId, measuredAt);
        response = response with
        {
            Values = AddCalculatedValues(response.Values.ToList(), calculatedParameters, latest)
        };

        return ServiceResult<MemberMeasurementResponse>.Success(response);
    }

    private async Task<ServiceResult?> ValidateMemberAccessAsync(long memberId, bool writeAccess)
    {
        var memberExists = await _dbContext.Members.AnyAsync(member =>
            member.Id == memberId && member.StudioId == _currentUser.StudioId);
        if (!memberExists)
        {
            return ServiceResult.NotFound(
                "Member not found.",
                "A member with this id does not exist.");
        }

        var isStaff = _currentUser.IsInRole(AuthRoles.Admin)
            || _currentUser.IsInRole(AuthRoles.Trainer);
        var isOwner = _currentUser.IsInRole(AuthRoles.Member)
            && _currentUser.MemberId == memberId;

        if (writeAccess && !isStaff)
        {
            return ServiceResult.Forbidden(
                "Measurement cannot be created.",
                "Only an admin or trainer can record member measurements.");
        }

        if (!writeAccess && !isStaff && !isOwner)
        {
            return ServiceResult.Forbidden(
                "Measurements cannot be viewed.",
                "Members can view only their own measurements.");
        }

        return null;
    }

    private async Task<List<MemberMeasurement>> LoadMeasurementsAsync(long memberId)
    {
        return await _dbContext.MemberMeasurements
            .AsNoTracking()
            .Where(measurement =>
                measurement.StudioId == _currentUser.StudioId
                && measurement.MemberId == memberId)
            .Include(measurement => measurement.MemberMeasurementValues)
                .ThenInclude(value => value.Parameter)
            .OrderBy(measurement => measurement.MeasuredAt)
            .ToListAsync();
    }

    private Task<List<MeasurementParameter>> LoadCalculatedParametersAsync()
    {
        return _dbContext.MeasurementParameters
            .AsNoTracking()
            .Where(parameter =>
                parameter.StudioId == _currentUser.StudioId
                && parameter.Status == "active"
                && parameter.Source == "calculated")
            .OrderBy(parameter => parameter.SortOrder)
            .ToListAsync();
    }

    private static IEnumerable<MemberMeasurementResponse> BuildHistory(
        IEnumerable<MemberMeasurement> measurements,
        IReadOnlyCollection<MeasurementParameter> calculatedParameters)
    {
        var latestManualValues = new Dictionary<string, decimal>();

        foreach (var measurement in measurements)
        {
            foreach (var value in measurement.MemberMeasurementValues)
            {
                latestManualValues[value.Parameter.Code] = value.NumericValue;
            }

            var response = ToResponse(measurement);
            yield return response with
            {
                Values = AddCalculatedValues(
                    response.Values.ToList(),
                    calculatedParameters,
                    latestManualValues)
            };
        }
    }

    private async Task<Dictionary<string, decimal>> GetLatestManualValuesAtAsync(
        long memberId,
        DateTime measuredAt)
    {
        var values = await _dbContext.MemberMeasurementValues
            .AsNoTracking()
            .Where(value =>
                value.Measurement.StudioId == _currentUser.StudioId
                && value.Measurement.MemberId == memberId
                && value.Measurement.MeasuredAt <= measuredAt
                && value.Parameter.Source == "manual")
            .Select(value => new
            {
                value.Parameter.Code,
                value.NumericValue,
                value.Measurement.MeasuredAt
            })
            .ToListAsync();

        return values
            .GroupBy(value => value.Code)
            .ToDictionary(
                group => group.Key,
                group => group.OrderByDescending(value => value.MeasuredAt).First().NumericValue);
    }

    private static void AddLatestCalculatedValues(
        List<MemberLatestMeasurementValueResponse> values,
        IReadOnlyCollection<MeasurementParameter> calculatedParameters)
    {
        var height = values.FirstOrDefault(value => value.Code == HeightCode);
        var weight = values.FirstOrDefault(value => value.Code == WeightCode);
        if (height is null || weight is null)
        {
            return;
        }

        foreach (var parameter in calculatedParameters.Where(item => item.CalculationType == "bmi"))
        {
            var bmi = CalculateBmi(height.Value, weight.Value, parameter.DecimalPlaces);
            values.Add(new MemberLatestMeasurementValueResponse(
                parameter.Id,
                parameter.Code,
                parameter.Name,
                parameter.Unit,
                bmi,
                parameter.DecimalPlaces,
                parameter.SortOrder,
                parameter.Source,
                height.MeasuredAt > weight.MeasuredAt ? height.MeasuredAt : weight.MeasuredAt));
        }
    }

    private static IReadOnlyCollection<MemberMeasurementValueResponse> AddCalculatedValues(
        List<MemberMeasurementValueResponse> values,
        IReadOnlyCollection<MeasurementParameter> calculatedParameters,
        IReadOnlyDictionary<string, decimal> latestManualValues)
    {
        if (!latestManualValues.TryGetValue(HeightCode, out var height)
            || !latestManualValues.TryGetValue(WeightCode, out var weight))
        {
            return values;
        }

        values.AddRange(calculatedParameters
            .Where(parameter => parameter.CalculationType == "bmi")
            .Select(parameter => new MemberMeasurementValueResponse(
                parameter.Id,
                parameter.Code,
                parameter.Name,
                parameter.Unit,
                CalculateBmi(height, weight, parameter.DecimalPlaces),
                parameter.DecimalPlaces,
                parameter.SortOrder,
                parameter.Source)));

        return values.OrderBy(value => value.SortOrder).ThenBy(value => value.Name).ToList();
    }

    private static decimal CalculateBmi(decimal heightCm, decimal weightKg, short decimalPlaces)
    {
        var heightMeters = heightCm / 100m;
        if (heightMeters <= 0)
        {
            throw new InvalidOperationException("Height must be greater than zero to calculate BMI.");
        }

        return decimal.Round(
            weightKg / (heightMeters * heightMeters),
            decimalPlaces,
            MidpointRounding.AwayFromZero);
    }

    private static ServiceResult? ValidateValue(MeasurementParameter parameter, decimal value)
    {
        if (parameter.Status != "active")
        {
            return ServiceResult.Conflict(
                "Measurement parameter is inactive.",
                $"The parameter '{parameter.Name}' is not available for new measurements.");
        }

        if (parameter.Source != "manual")
        {
            return ServiceResult.Conflict(
                "Calculated measurement cannot be entered manually.",
                $"The parameter '{parameter.Name}' is calculated by the system.");
        }

        if (parameter.MinValue.HasValue && value < parameter.MinValue.Value
            || parameter.MaxValue.HasValue && value > parameter.MaxValue.Value)
        {
            return ServiceResult.Conflict(
                "Measurement value is outside the allowed range.",
                $"The value for '{parameter.Name}' is outside its configured range.");
        }

        if (parameter.ValueType == "integer" && value != decimal.Truncate(value))
        {
            return ServiceResult.Conflict(
                "Measurement value must be an integer.",
                $"The parameter '{parameter.Name}' does not accept decimal values.");
        }

        var rounded = decimal.Round(value, parameter.DecimalPlaces);
        if (rounded != value)
        {
            return ServiceResult.Conflict(
                "Measurement value has too many decimal places.",
                $"The parameter '{parameter.Name}' accepts at most {parameter.DecimalPlaces} decimal places.");
        }

        return null;
    }

    private static MemberMeasurementResponse ToResponse(MemberMeasurement measurement)
    {
        return new MemberMeasurementResponse(
            measurement.Id,
            measurement.MemberId,
            measurement.MeasuredAt,
            measurement.RecordedByUserId,
            measurement.Note,
            measurement.MemberMeasurementValues
                .Select(value => new MemberMeasurementValueResponse(
                    value.ParameterId,
                    value.Parameter.Code,
                    value.Parameter.Name,
                    value.Parameter.Unit,
                    value.NumericValue,
                    value.Parameter.DecimalPlaces,
                    value.Parameter.SortOrder,
                    value.Parameter.Source))
                .OrderBy(value => value.SortOrder)
                .ThenBy(value => value.Name)
                .ToList());
    }

    private static ServiceResult<T> ToTypedFailure<T>(ServiceResult result)
    {
        return new ServiceResult<T>(result.Status, default, result.Error);
    }
}
