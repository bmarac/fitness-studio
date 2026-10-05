using AutoMapper;
using AutoMapper.QueryableExtensions;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Dtos.ClassSessions;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.ClassSessions;

public class ClassSessionsService : IClassSessionsService
{
    private readonly AutoMapper.IConfigurationProvider _configurationProvider;
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;
    private readonly IMapper _mapper;

    public ClassSessionsService(
        FitnessStudioDbContext dbContext,
        IMapper mapper,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _mapper = mapper;
        _currentUser = currentUser;
        _configurationProvider = mapper.ConfigurationProvider;
    }

    public Task<List<ClassSessionResponse>> GetClassSessionsAsync()
    {
        return _dbContext.ClassSessions
            .AsNoTracking()
            .Where(classSession => classSession.StudioId == _currentUser.StudioId)
            .OrderBy(classSession => classSession.StartsAt)
            .ProjectTo<ClassSessionResponse>(_configurationProvider)
            .ToListAsync();
    }

    public Task<List<ClassSessionResponse>> GetMyClassSessionsAsync()
    {
        var trainerId = _currentUser.TrainerId
            ?? throw new InvalidOperationException(
                "Authenticated trainer is missing the trainer_id claim.");

        return _dbContext.ClassSessions
            .AsNoTracking()
            .Where(classSession =>
                classSession.StudioId == _currentUser.StudioId
                && classSession.TrainerId == trainerId)
            .OrderBy(classSession => classSession.StartsAt)
            .ProjectTo<ClassSessionResponse>(_configurationProvider)
            .ToListAsync();
    }

    public async Task<ServiceResult<ClassSessionResponse>> GetClassSessionAsync(long id)
    {
        var classSession = await _dbContext.ClassSessions
            .AsNoTracking()
            .Where(classSession =>
                classSession.Id == id && classSession.StudioId == _currentUser.StudioId)
            .ProjectTo<ClassSessionResponse>(_configurationProvider)
            .FirstOrDefaultAsync();

        if (classSession is null)
        {
            return ServiceResult<ClassSessionResponse>.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.");
        }

        return ServiceResult<ClassSessionResponse>.Success(classSession);
    }

    public async Task<ServiceResult<ClassSessionResponse>> CreateClassSessionAsync(CreateClassSessionRequest request)
    {
        var validationResult = await ValidateReferencesAndTimesAsync(
            request.ClassTypeId,
            request.TrainerId,
            request.RecurringScheduleId,
            request.StartsAt,
            request.EndsAt);

        if (validationResult.Status != ServiceResultStatus.Success)
        {
            return new ServiceResult<ClassSessionResponse>(validationResult.Status, default, validationResult.Error);
        }

        var classSession = _mapper.Map<ClassSession>(request);
        classSession.StudioId = _currentUser.StudioId;
        classSession.Status = NormalizeValue(classSession.Status);
        classSession.CreatedAt = DateTime.UtcNow;
        classSession.UpdatedAt = DateTime.UtcNow;

        _dbContext.ClassSessions.Add(classSession);
        await _dbContext.SaveChangesAsync();

        return await GetClassSessionAsync(classSession.Id);
    }

    public async Task<ServiceResult> UpdateClassSessionAsync(long id, UpdateClassSessionRequest request)
    {
        var classSession = await _dbContext.ClassSessions.FirstOrDefaultAsync(classSession =>
            classSession.Id == id && classSession.StudioId == _currentUser.StudioId);

        if (classSession is null)
        {
            return ServiceResult.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.");
        }

        var validationResult = await ValidateReferencesAndTimesAsync(
            request.ClassTypeId,
            request.TrainerId,
            null,
            request.StartsAt,
            request.EndsAt);

        if (validationResult.Status != ServiceResultStatus.Success)
        {
            return validationResult;
        }

        _mapper.Map(request, classSession);
        classSession.Status = NormalizeValue(classSession.Status);
        classSession.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteClassSessionAsync(long id)
    {
        var classSession = await _dbContext.ClassSessions.FirstOrDefaultAsync(classSession =>
            classSession.Id == id && classSession.StudioId == _currentUser.StudioId);

        if (classSession is null)
        {
            return ServiceResult.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.");
        }

        _dbContext.ClassSessions.Remove(classSession);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Class session cannot be deleted.",
                "Class session cannot be deleted because related bookings exist.");
        }

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> CancelClassSessionAsync(long id)
    {
        var classSession = await _dbContext.ClassSessions
            .Include(item => item.Bookings)
            .FirstOrDefaultAsync(item =>
                item.Id == id && item.StudioId == _currentUser.StudioId);

        if (classSession is null)
        {
            return ServiceResult.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.");
        }

        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == classSession.TrainerId;

        if (!isAdmin && !isAssignedTrainer)
        {
            return ServiceResult.Forbidden(
                "Class session cannot be cancelled.",
                "Trainers can cancel only their own class sessions.");
        }

        if (classSession.Status == ClassSessionStatuses.Cancelled)
        {
            return ServiceResult.Conflict(
                "Class session is already cancelled.",
                "The selected class session has already been cancelled.");
        }

        if (classSession.Status == ClassSessionStatuses.Completed)
        {
            return ServiceResult.Conflict(
                "Completed class session cannot be cancelled.",
                "A completed class session cannot be cancelled.");
        }

        var now = DateTime.UtcNow;
        classSession.Status = ClassSessionStatuses.Cancelled;
        classSession.UpdatedAt = now;

        foreach (var booking in classSession.Bookings.Where(item =>
            item.Status != BookingStatuses.Cancelled))
        {
            booking.Status = BookingStatuses.Cancelled;
            booking.CancelledAt = now;
            booking.UpdatedAt = now;
        }

        await _dbContext.SaveChangesAsync();
        return ServiceResult.Success();
    }

    private async Task<ServiceResult> ValidateReferencesAndTimesAsync(
        long classTypeId,
        long trainerId,
        long? recurringScheduleId,
        DateTime startsAt,
        DateTime endsAt)
    {
        if (endsAt <= startsAt)
        {
            return ServiceResult.Conflict(
                "Invalid class session time.",
                "Class session end time must be after start time.");
        }

        if (!await _dbContext.ClassTypes.AnyAsync(classType =>
            classType.Id == classTypeId && classType.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Class type does not exist.",
                "Class session must reference an existing class type.");
        }

        if (!await _dbContext.Trainers.AnyAsync(trainer =>
            trainer.Id == trainerId && trainer.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Trainer does not exist.",
                "Class session must reference an existing trainer.");
        }

        if (recurringScheduleId.HasValue
            && !await _dbContext.RecurringClassSchedules.AnyAsync(schedule =>
                schedule.Id == recurringScheduleId.Value
                && schedule.StudioId == _currentUser.StudioId))
        {
            return ServiceResult.Conflict(
                "Recurring schedule does not exist.",
                "Class session must reference an existing recurring schedule.");
        }

        return ServiceResult.Success();
    }

    private static string NormalizeValue(string value)
    {
        return value.ToLowerInvariant();
    }
}
