using FitnessStudio.Api.Dtos.Bookings;

namespace FitnessStudio.Api.Services.Interfaces;

public interface IBookingsService
{
    Task<List<BookingResponse>> GetBookingsAsync();

    Task<ServiceResult<MemberBookingsPageResponse>> GetMemberBookingsAsync(
        MemberBookingsQuery query);

    Task<ServiceResult<List<BookingResponse>>> GetBookingsByClassSessionIdAsync(
        long classSessionId);

    Task<ServiceResult<BookingResponse>> GetBookingAsync(long id);

    Task<ServiceResult<BookingResponse>> CreateBookingAsync(CreateBookingRequest request);

    Task<ServiceResult> UpdateBookingStatusAsync(long id, UpdateBookingStatusRequest request);

    Task<ServiceResult> CancelBookingAsync(long id);
}
