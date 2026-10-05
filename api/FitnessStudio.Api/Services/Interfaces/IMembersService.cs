using FitnessStudio.Api.Dtos.Members;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMembersService
{
    Task<List<MemberResponse>> GetMembersAsync();

    Task<ServiceResult<MemberResponse>> GetMemberAsync(long id);

    Task<ServiceResult<MemberResponse>> CreateMemberAsync(CreateMemberRequest request);

    Task<ServiceResult> UpdateMemberAsync(long id, UpdateMemberRequest request);

    Task<ServiceResult> DeleteMemberAsync(long id);
}
