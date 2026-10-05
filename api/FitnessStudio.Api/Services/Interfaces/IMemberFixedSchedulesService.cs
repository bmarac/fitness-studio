using FitnessStudio.Api.Dtos.MemberFixedSchedules;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMemberFixedSchedulesService
{
    Task<List<MemberFixedScheduleResponse>> GetSchedulesAsync();
    Task<List<MemberFixedScheduleResponse>> GetCurrentMemberSchedulesAsync();
    Task<ServiceResult<MemberFixedScheduleResponse>> GetScheduleAsync(long id);
    Task<ServiceResult<MemberFixedScheduleResponse>> CreateScheduleAsync(CreateMemberFixedScheduleRequest request);
    Task<ServiceResult> UpdateScheduleAsync(long id, UpdateMemberFixedScheduleRequest request);
    Task<ServiceResult> CancelScheduleAsync(long id, CancelMemberFixedScheduleRequest request);
    Task<ServiceResult> DeleteScheduleAsync(long id);
}
