using AutoMapper;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Members;
using FitnessStudio.Api.Dtos.Members;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Members;

public class MembersService : IMembersService
{
    private readonly FitnessStudioDbContext _dbContext;
    private readonly ICurrentUserContext _currentUser;
    private readonly IMapper _mapper;

    public MembersService(
        FitnessStudioDbContext dbContext,
        IMapper mapper,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _mapper = mapper;
        _currentUser = currentUser;
    }

    public async Task<List<MemberResponse>> GetMembersAsync()
    {
        var members = await _dbContext.Members
            .AsNoTracking()
            .Where(member => member.StudioId == _currentUser.StudioId)
            .OrderBy(member => member.LastName)
            .ThenBy(member => member.FirstName)
            .ToListAsync();

        return _mapper.Map<List<MemberResponse>>(members);
    }

    public async Task<ServiceResult<MemberResponse>> GetMemberAsync(long id)
    {
        var member = await _dbContext.Members
            .AsNoTracking()
            .FirstOrDefaultAsync(member => member.Id == id && member.StudioId == _currentUser.StudioId);

        if (member is null)
        {
            return ServiceResult<MemberResponse>.NotFound(
                "Member not found.",
                "A member with this id does not exist.");
        }

        return ServiceResult<MemberResponse>.Success(_mapper.Map<MemberResponse>(member));
    }

    public async Task<ServiceResult<MemberResponse>> CreateMemberAsync(CreateMemberRequest request)
    {
        if (await EmailExistsAsync(request.Email))
        {
            return ServiceResult<MemberResponse>.Conflict(
                "Member email already exists.",
                "A member with this email already exists.");
        }

        var member = _mapper.Map<Member>(request);
        member.StudioId = _currentUser.StudioId;
        member.Status = NormalizeStatus(member.Status);
        member.CreatedAt = DateTime.UtcNow;
        member.UpdatedAt = DateTime.UtcNow;

        _dbContext.Members.Add(member);
        await _dbContext.SaveChangesAsync();

        return ServiceResult<MemberResponse>.Success(_mapper.Map<MemberResponse>(member));
    }

    public async Task<ServiceResult> UpdateMemberAsync(long id, UpdateMemberRequest request)
    {
        var member = await _dbContext.Members.FirstOrDefaultAsync(member =>
            member.Id == id && member.StudioId == _currentUser.StudioId);

        if (member is null)
        {
            return ServiceResult.NotFound(
                "Member not found.",
                "A member with this id does not exist.");
        }

        if (await EmailExistsAsync(request.Email, id))
        {
            return ServiceResult.Conflict(
                "Member email already exists.",
                "A member with this email already exists.");
        }

        _mapper.Map(request, member);
        member.Status = NormalizeStatus(member.Status);
        member.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> DeleteMemberAsync(long id)
    {
        var member = await _dbContext.Members.FirstOrDefaultAsync(member =>
            member.Id == id && member.StudioId == _currentUser.StudioId);

        if (member is null)
        {
            return ServiceResult.NotFound(
                "Member not found.",
                "A member with this id does not exist.");
        }

        _dbContext.Members.Remove(member);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Member cannot be deleted.",
                "Member cannot be deleted because related records exist.");
        }

        return ServiceResult.Success();
    }

    private static string NormalizeStatus(string status)
    {
        return status.ToLowerInvariant();
    }

    private Task<bool> EmailExistsAsync(string email, long? ignoredMemberId = null)
    {
        return _dbContext.Members.AnyAsync(member =>
            member.StudioId == _currentUser.StudioId
            && member.Email == email
            && (!ignoredMemberId.HasValue || member.Id != ignoredMemberId.Value));
    }
}
