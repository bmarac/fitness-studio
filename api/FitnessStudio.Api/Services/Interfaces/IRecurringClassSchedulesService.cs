using FitnessStudio.Api.Dtos.RecurringClassSchedules;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IRecurringClassSchedulesService
{
    Task<List<RecurringClassScheduleResponse>> GetSchedulesAsync();
    Task<ServiceResult<RecurringClassScheduleResponse>> GetScheduleAsync(long id);
    Task<ServiceResult<RecurringClassScheduleResponse>> CreateScheduleAsync(CreateRecurringClassScheduleRequest request);
    Task<ServiceResult> UpdateScheduleAsync(long id, UpdateRecurringClassScheduleRequest request);
    Task<ServiceResult> DeleteScheduleAsync(long id);
}
