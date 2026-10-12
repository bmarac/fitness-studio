using FitnessStudio.Api.Dtos.Payments;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IPaymentSettingsService
{
    Task<PaymentSettingsResponse> GetAsync(long? studioId = null);
    Task<ServiceResult<PaymentSettingsResponse>> UpdateAsync(UpdatePaymentSettingsRequest request);
}
