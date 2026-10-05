using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.ClassTypes;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.ClassTypes;

public class ClassTypesService : IClassTypesService
{
    private readonly FitnessStudioDbContext _dbContext;
    private readonly ICurrentUserContext _currentUser;
    private readonly IMapper _mapper;

    public ClassTypesService(
        FitnessStudioDbContext dbContext,
        IMapper mapper,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _mapper = mapper;
        _currentUser = currentUser;
    }

    public async Task<List<ClassTypeResponse>> GetClassTypesAsync()
    {
        var classTypes = await _dbContext.ClassTypes
            .AsNoTracking()
            .Where(classType => classType.StudioId == _currentUser.StudioId)
            .OrderBy(classType => classType.Name)
            .ToListAsync();

        return _mapper.Map<List<ClassTypeResponse>>(classTypes);
    }

    public async Task<ServiceResult<ClassTypeResponse>> GetClassTypeAsync(long id)
    {
        var classType = await _dbContext.ClassTypes
            .AsNoTracking()
            .FirstOrDefaultAsync(classType =>
                classType.Id == id && classType.StudioId == _currentUser.StudioId);

        if (classType is null)
        {
            return ServiceResult<ClassTypeResponse>.NotFound(
                "Class type not found.",
                "A class type with this id does not exist.");
        }

        return ServiceResult<ClassTypeResponse>.Success(_mapper.Map<ClassTypeResponse>(classType));
    }

    public async Task<ServiceResult<ClassTypeResponse>> CreateClassTypeAsync(CreateClassTypeRequest request)
    {
        if (await NameExistsAsync(request.Name))
        {
            return ServiceResult<ClassTypeResponse>.Conflict(
                "Class type name already exists.",
                "A class type with this name already exists.");
        }

        var classType = _mapper.Map<ClassType>(request);
        classType.StudioId = _currentUser.StudioId;
        classType.DifficultyLevel = NormalizeValue(classType.DifficultyLevel);
        classType.Status = NormalizeValue(classType.Status);
        classType.CreatedAt = DateTime.UtcNow;
        classType.UpdatedAt = DateTime.UtcNow;

        _dbContext.ClassTypes.Add(classType);
        await _dbContext.SaveChangesAsync();

        return ServiceResult<ClassTypeResponse>.Success(_mapper.Map<ClassTypeResponse>(classType));
    }

    public async Task<ServiceResult> UpdateClassTypeAsync(long id, UpdateClassTypeRequest request)
    {
        var classType = await _dbContext.ClassTypes.FirstOrDefaultAsync(classType =>
            classType.Id == id && classType.StudioId == _currentUser.StudioId);

        if (classType is null)
        {
            return ServiceResult.NotFound(
                "Class type not found.",
                "A class type with this id does not exist.");
        }

        if (await NameExistsAsync(request.Name, id))
        {
            return ServiceResult.Conflict(
                "Class type name already exists.",
                "A class type with this name already exists.");
        }

        _mapper.Map(request, classType);
        classType.DifficultyLevel = NormalizeValue(classType.DifficultyLevel);
        classType.Status = NormalizeValue(classType.Status);
        classType.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteClassTypeAsync(long id)
    {
        var classType = await _dbContext.ClassTypes.FirstOrDefaultAsync(classType =>
            classType.Id == id && classType.StudioId == _currentUser.StudioId);

        if (classType is null)
        {
            return ServiceResult.NotFound(
                "Class type not found.",
                "A class type with this id does not exist.");
        }

        _dbContext.ClassTypes.Remove(classType);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Class type cannot be deleted.",
                "Class type cannot be deleted because related class sessions exist.");
        }

        return ServiceResult.Success();
    }

    private static string NormalizeValue(string value)
    {
        return value.ToLowerInvariant();
    }

    private Task<bool> NameExistsAsync(string name, long? ignoredClassTypeId = null)
    {
        return _dbContext.ClassTypes.AnyAsync(classType =>
            classType.StudioId == _currentUser.StudioId
            && classType.Name == name
            && (!ignoredClassTypeId.HasValue || classType.Id != ignoredClassTypeId.Value));
    }
}
