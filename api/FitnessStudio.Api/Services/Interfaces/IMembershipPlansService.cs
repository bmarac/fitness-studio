using FitnessStudio.Api.Dtos.MembershipPlans;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMembershipPlansService
{
    Task<List<MembershipPlanResponse>> GetPlansAsync();
    Task<ServiceResult<MembershipPlanResponse>> GetPlanAsync(long id);
    Task<ServiceResult<MembershipPlanResponse>> CreatePlanAsync(CreateMembershipPlanRequest request);
    Task<ServiceResult> UpdatePlanAsync(long id, UpdateMembershipPlanRequest request);
    Task<ServiceResult> DeletePlanAsync(long id);
}
