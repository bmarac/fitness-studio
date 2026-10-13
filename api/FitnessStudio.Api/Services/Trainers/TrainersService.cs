using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Trainers;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Trainers;

public class TrainersService : ITrainersService
{
    private readonly FitnessStudioDbContext _dbContext;
    private readonly ICurrentUserContext _currentUser;
    private readonly IMapper _mapper;

    public TrainersService(
        FitnessStudioDbContext dbContext,
        IMapper mapper,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _mapper = mapper;
        _currentUser = currentUser;
    }

    public async Task<List<TrainerResponse>> GetTrainersAsync()
    {
        var trainers = await _dbContext.Trainers
            .AsNoTracking()
            .Where(trainer => trainer.StudioId == _currentUser.StudioId)
            .OrderBy(trainer => trainer.LastName)
            .ThenBy(trainer => trainer.FirstName)
            .ToListAsync();

        return _mapper.Map<List<TrainerResponse>>(trainers);
    }

    public async Task<ServiceResult<TrainerResponse>> GetTrainerAsync(long id)
    {
        var trainer = await _dbContext.Trainers
            .AsNoTracking()
            .FirstOrDefaultAsync(trainer => trainer.Id == id && trainer.StudioId == _currentUser.StudioId);

        if (trainer is null)
        {
            return ServiceResult<TrainerResponse>.NotFound(
                "Trainer not found.",
                "A trainer with this id does not exist.");
        }

        return ServiceResult<TrainerResponse>.Success(_mapper.Map<TrainerResponse>(trainer));
    }

    public async Task<ServiceResult<TrainerResponse>> CreateTrainerAsync(CreateTrainerRequest request)
    {
        var email = NormalizeEmail(request.Email);
        if (await EmailExistsAsync(email))
        {
            return ServiceResult<TrainerResponse>.Conflict(
                "Profile email already exists.",
                "A member or trainer with this email already exists in the studio.");
        }

        var trainer = _mapper.Map<Trainer>(request);
        trainer.Email = email;
        trainer.StudioId = _currentUser.StudioId;
        trainer.Status = NormalizeStatus(trainer.Status);
        trainer.CreatedAt = DateTime.UtcNow;
        trainer.UpdatedAt = DateTime.UtcNow;

        _dbContext.Trainers.Add(trainer);
        await _dbContext.SaveChangesAsync();

        return ServiceResult<TrainerResponse>.Success(_mapper.Map<TrainerResponse>(trainer));
    }

    public async Task<ServiceResult> UpdateTrainerAsync(long id, UpdateTrainerRequest request)
    {
        var trainer = await _dbContext.Trainers.FirstOrDefaultAsync(trainer =>
            trainer.Id == id && trainer.StudioId == _currentUser.StudioId);

        if (trainer is null)
        {
            return ServiceResult.NotFound(
                "Trainer not found.",
                "A trainer with this id does not exist.");
        }

        var email = NormalizeEmail(request.Email);
        if (await EmailExistsAsync(email, id))
        {
            return ServiceResult.Conflict(
                "Profile email already exists.",
                "A member or trainer with this email already exists in the studio.");
        }

        _mapper.Map(request, trainer);
        trainer.Email = email;
        trainer.Status = NormalizeStatus(trainer.Status);
        trainer.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteTrainerAsync(long id)
    {
        var trainer = await _dbContext.Trainers.FirstOrDefaultAsync(trainer =>
            trainer.Id == id && trainer.StudioId == _currentUser.StudioId);

        if (trainer is null)
        {
            return ServiceResult.NotFound(
                "Trainer not found.",
                "A trainer with this id does not exist.");
        }

        _dbContext.Trainers.Remove(trainer);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Trainer cannot be deleted.",
                "Trainer cannot be deleted because related class sessions exist.");
        }

        return ServiceResult.Success();
    }

    private static string NormalizeStatus(string status)
    {
        return status.ToLowerInvariant();
    }

    private async Task<bool> EmailExistsAsync(string email, long? ignoredTrainerId = null)
    {
        return await _dbContext.Trainers.AnyAsync(trainer =>
            trainer.StudioId == _currentUser.StudioId
            && trainer.Email.ToLower() == email
            && (!ignoredTrainerId.HasValue || trainer.Id != ignoredTrainerId.Value))
            || await _dbContext.Members.AnyAsync(member =>
                member.StudioId == _currentUser.StudioId
                && member.Email.ToLower() == email);
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
