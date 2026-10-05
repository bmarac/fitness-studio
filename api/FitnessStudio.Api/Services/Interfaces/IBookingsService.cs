using FitnessStudio.Api.Dtos.Bookings;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IBookingsService
{
    Task<List<BookingResponse>> GetBookingsAsync();

    Task<int> GetCurrentMemberUsageAsync(DateOnly startsOn, DateOnly endsOn);

    Task<ServiceResult<List<BookingResponse>>> GetBookingsByClassSessionIdAsync(
        long classSessionId);

    Task<ServiceResult<BookingResponse>> GetBookingAsync(long id);

    Task<ServiceResult<BookingResponse>> CreateBookingAsync(CreateBookingRequest request);

    Task<ServiceResult> UpdateBookingStatusAsync(long id, UpdateBookingStatusRequest request);

    Task<ServiceResult> CancelBookingAsync(long id);
}
