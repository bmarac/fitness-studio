using FitnessStudio.Api.Dtos.Payments;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IMembershipPaymentsService
{
    Task<List<MembershipPaymentResponse>> GetMineAsync();
    Task<List<MembershipPaymentResponse>> GetAllAsync(string? view, long? memberId);
    Task<ServiceResult<MembershipPaymentResponse>> GetAsync(long id);
    Task<MembershipPaymentSummaryResponse> GetSummaryAsync();
    Task<ServiceResult> ReportAsync(long id);
    Task<ServiceResult> ConfirmAsync(long id);
    Task<ServiceResult> RejectReportAsync(long id);
    Task<ServiceResult> ReopenAsync(long id);
    Task<ServiceResult<string>> GetHub3PayloadAsync(long id);
}
