using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Extensions;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FitnessStudio.Api.Controllers;

[ApiController]
[Route("api/bookings")]
public class BookingsController : ControllerBase
{
    private readonly IBookingsService _bookingsService;

    public BookingsController(IBookingsService bookingsService)
    {
        _bookingsService = bookingsService;
    }

    [HttpGet]
    public async Task<ActionResult<List<BookingResponse>>> GetBookings(
        [FromQuery] long? classSessionId)
    {
        if (!classSessionId.HasValue)
        {
            return Ok(await _bookingsService.GetBookingsAsync());
        }

        var result = await _bookingsService.GetBookingsByClassSessionIdAsync(
            classSessionId.Value);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpGet("{id:long}")]
    public async Task<ActionResult<BookingResponse>> GetBooking(long id)
    {
        var result = await _bookingsService.GetBookingAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? Ok(result.Value)
            : this.ToActionResult(result);
    }

    [HttpPost]
    public async Task<ActionResult<BookingResponse>> CreateBooking(CreateBookingRequest request)
    {
        var result = await _bookingsService.CreateBookingAsync(request);

        return result.Status == ServiceResultStatus.Success
            ? CreatedAtAction(nameof(GetBooking), new { id = result.Value!.Id }, result.Value)
            : this.ToActionResult(result);
    }

    [HttpPatch("{id:long}/status")]
    public async Task<IActionResult> UpdateBookingStatus(long id, UpdateBookingStatusRequest request)
    {
        var result = await _bookingsService.UpdateBookingStatusAsync(id, request);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> CancelBooking(long id)
    {
        var result = await _bookingsService.CancelBookingAsync(id);

        return result.Status == ServiceResultStatus.Success
            ? NoContent()
            : this.ToActionResult(result);
    }
}
