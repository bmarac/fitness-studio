using FitnessStudio.Api.Dtos.MemberMemberships;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMemberMembershipsService
{
    Task<List<MemberMembershipResponse>> GetMembershipsAsync();
    Task<MemberMembershipResponse?> GetCurrentMemberMembershipAsync();
    Task<ServiceResult<MemberMembershipResponse>> GetMembershipAsync(long id);
    Task<ServiceResult<MemberMembershipResponse>> CreateMembershipAsync(CreateMemberMembershipRequest request);
    Task<ServiceResult> UpdateMembershipAsync(long id, UpdateMemberMembershipRequest request);
    Task<ServiceResult> DeleteMembershipAsync(long id);
}
