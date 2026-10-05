using FitnessStudio.Api.Dtos.MemberMeasurements;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMemberMeasurementsService
{
    Task<ServiceResult<List<MemberMeasurementResponse>>> GetMeasurementsAsync(long memberId);
    Task<ServiceResult<MemberLatestMeasurementsResponse>> GetLatestMeasurementsAsync(long memberId);
    Task<ServiceResult<MemberMeasurementResponse>> CreateMeasurementAsync(
        long memberId,
        CreateMemberMeasurementRequest request);
}
