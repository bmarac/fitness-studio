using FitnessStudio.Api.Dtos.MeasurementParameters;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMeasurementParametersService
{
    Task<List<MeasurementParameterResponse>> GetParametersAsync();
    Task<ServiceResult<MeasurementParameterResponse>> GetParameterAsync(long id);
    Task<ServiceResult<MeasurementParameterResponse>> CreateParameterAsync(
        CreateMeasurementParameterRequest request);
    Task<ServiceResult> UpdateParameterAsync(long id, UpdateMeasurementParameterRequest request);
    Task<ServiceResult> DeleteParameterAsync(long id);
}
