using FitnessStudio.Api.Dtos.ClassTypes;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IClassTypesService
{
    Task<List<ClassTypeResponse>> GetClassTypesAsync();

    Task<ServiceResult<ClassTypeResponse>> GetClassTypeAsync(long id);

    Task<ServiceResult<ClassTypeResponse>> CreateClassTypeAsync(CreateClassTypeRequest request);

    Task<ServiceResult> UpdateClassTypeAsync(long id, UpdateClassTypeRequest request);

    Task<ServiceResult> DeleteClassTypeAsync(long id);
}
