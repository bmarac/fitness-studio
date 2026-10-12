using System.Text;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Dtos.Payments;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ZXing;
using ZXing.Common;
using ZXing.PDF417.Internal;

namespace FitnessStudio.Api.Controllers;

[ApiController, Authorize, Route("api/membership-payments")]
public class MembershipPaymentsController : ControllerBase
{
    private readonly IMembershipPaymentsService _service;
    public MembershipPaymentsController(IMembershipPaymentsService service) => _service = service;

    [HttpGet("mine")]
    public async Task<ActionResult<List<MembershipPaymentResponse>>> Mine() => Ok(await _service.GetMineAsync());

    [HttpGet, Authorize(Roles = AuthRoles.Admin)]
    public async Task<ActionResult<List<MembershipPaymentResponse>>> All([FromQuery] string? view, [FromQuery] long? memberId)
        => Ok(await _service.GetAllAsync(view, memberId));

    [HttpGet("summary"), Authorize(Roles = AuthRoles.Admin)]
    public async Task<ActionResult<MembershipPaymentSummaryResponse>> Summary() => Ok(await _service.GetSummaryAsync());

    [HttpGet("{id:long}")]
    public async Task<ActionResult<MembershipPaymentResponse>> Get(long id)
    {
        var result = await _service.GetAsync(id);
        return result.Status == ServiceResultStatus.Success ? Ok(result.Value) : this.ToActionResult(result);
    }

    [HttpPost("{id:long}/report")]
    public async Task<IActionResult> Report(long id) => Result(await _service.ReportAsync(id));
    [HttpPost("{id:long}/confirm"), Authorize(Roles = AuthRoles.Admin)]
    public async Task<IActionResult> Confirm(long id) => Result(await _service.ConfirmAsync(id));
    [HttpPost("{id:long}/reject-report"), Authorize(Roles = AuthRoles.Admin)]
    public async Task<IActionResult> Reject(long id) => Result(await _service.RejectReportAsync(id));
    [HttpPost("{id:long}/reopen"), Authorize(Roles = AuthRoles.Admin)]
    public async Task<IActionResult> Reopen(long id) => Result(await _service.ReopenAsync(id));

    [HttpGet("{id:long}/barcode")]
    public async Task<IActionResult> Barcode(long id)
    {
        var result = await _service.GetHub3PayloadAsync(id);
        if (result.Status != ServiceResultStatus.Success) return this.ToActionResult(result);
        var writer = new MultiFormatWriter();
        var matrix = writer.encode(result.Value, BarcodeFormat.PDF_417, 580, 260, new Dictionary<EncodeHintType, object>
        {
            [EncodeHintType.ERROR_CORRECTION] = 4,
            [EncodeHintType.PDF417_COMPACT] = false,
            [EncodeHintType.PDF417_DIMENSIONS] = new Dimensions(9, 9, 3, 90),
            [EncodeHintType.CHARACTER_SET] = "UTF-8",
            [EncodeHintType.MARGIN] = 2
        });
        return Content(ToSvg(matrix), "image/svg+xml", Encoding.UTF8);
    }

    private IActionResult Result(ServiceResult result) => result.Status == ServiceResultStatus.Success ? NoContent() : this.ToActionResult(result);
    private static string ToSvg(BitMatrix matrix)
    {
        var svg = new StringBuilder($"<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 {matrix.Width} {matrix.Height}\" shape-rendering=\"crispEdges\"><rect width=\"100%\" height=\"100%\" fill=\"white\"/><path d=\"");
        for (var y = 0; y < matrix.Height; y++) for (var x = 0; x < matrix.Width; x++) if (matrix[x, y]) svg.Append($"M{x} {y}h1v1h-1z");
        return svg.Append("\" fill=\"black\"/></svg>").ToString();
    }
}
