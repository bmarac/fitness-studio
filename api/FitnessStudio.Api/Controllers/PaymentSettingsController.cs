using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController, Authorize, Route("api/payment-settings")]
public class PaymentSettingsController : ControllerBase
{
    private readonly IPaymentSettingsService _service;
    public PaymentSettingsController(IPaymentSettingsService service) => _service = service;

    [HttpGet, Authorize(Roles = AuthRoles.Admin)]
    public async Task<ActionResult<PaymentSettingsResponse>> Get() => Ok(await _service.GetAsync());

    [HttpPut, Authorize(Roles = AuthRoles.Admin)]
    public async Task<ActionResult<PaymentSettingsResponse>> Update(UpdatePaymentSettingsRequest request)
    {
        var result = await _service.UpdateAsync(request);
        return result.Status == Services.ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }
}
