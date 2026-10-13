using FitnessStudio.Api.Dtos.ClassSessions;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IClassSessionsService
{
    Task<List<ClassSessionResponse>> GetClassSessionsAsync(
        DateTime? from = null,
        DateTime? to = null);

    Task<List<ClassSessionResponse>> GetMyClassSessionsAsync();

    Task<ServiceResult<ClassSessionResponse>> GetClassSessionAsync(long id);

    Task<ServiceResult<ClassSessionResponse>> CreateClassSessionAsync(CreateClassSessionRequest request);

    Task<ServiceResult> UpdateClassSessionAsync(long id, UpdateClassSessionRequest request);

    Task<ServiceResult> CancelClassSessionAsync(long id);

    Task<ServiceResult> DeleteClassSessionAsync(long id);
}
