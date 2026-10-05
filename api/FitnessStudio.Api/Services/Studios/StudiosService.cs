using FitnessStudio.Api.Data;
using FitnessStudio.Api.Dtos.Studios;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Studios;

public class StudiosService : IStudiosService
{
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;

    public StudiosService(FitnessStudioDbContext dbContext, ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<ServiceResult<StudioResponse>> GetCurrentStudioAsync()
    {
        var studio = await _dbContext.Studios
            .AsNoTracking()
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => new StudioResponse(
                studio.Id,
                studio.Name,
                studio.Timezone,
                studio.Status))
            .FirstOrDefaultAsync();

        return studio is null
            ? ServiceResult<StudioResponse>.NotFound(
                "Studio not found.",
                "The authenticated user's studio does not exist.")
            : ServiceResult<StudioResponse>.Success(studio);
    }

    public async Task<ServiceResult> UpdateCurrentStudioAsync(UpdateStudioRequest request)
    {
        if (!IsValidTimezone(request.Timezone))
        {
            return ServiceResult.Conflict(
                "Invalid timezone.",
                "The supplied timezone is not recognized by the server.");
        }

        var studio = await _dbContext.Studios.FirstOrDefaultAsync(studio =>
            studio.Id == _currentUser.StudioId);

        if (studio is null)
        {
            return ServiceResult.NotFound(
                "Studio not found.",
                "The authenticated user's studio does not exist.");
        }

        studio.Name = request.Name.Trim();
        studio.Timezone = request.Timezone.Trim();
        studio.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    private static bool IsValidTimezone(string timezone)
    {
        try
        {
            TimeZoneInfo.FindSystemTimeZoneById(timezone.Trim());
            return true;
        }
        catch (TimeZoneNotFoundException)
        {
            return false;
        }
        catch (InvalidTimeZoneException)
        {
            return false;
        }
    }
}
