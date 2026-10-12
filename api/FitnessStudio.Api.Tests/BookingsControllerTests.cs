using FitnessStudio.Api.Controllers;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Services;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Xunit;

namespace FitnessStudio.Api.Tests;

public class BookingsControllerTests
{
    [Fact]
    public async Task GetBookingsWithoutSessionFilterReturnsAllBookings()
    {
        var bookings = new List<BookingResponse> { Booking() };
        var service = new FakeBookingsService { GetBookingsResult = bookings };
        var controller = new BookingsController(service);

        var action = await controller.GetBookings(null);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(bookings, ok.Value);
        Assert.Equal(1, service.GetBookingsCalls);
        Assert.Null(service.LastClassSessionId);
    }

    [Fact]
    public async Task GetBookingsWithSessionFilterReturnsFilteredBookings()
    {
        var bookings = new List<BookingResponse> { Booking() };
        var service = new FakeBookingsService
        {
            GetByClassSessionResult = ServiceResult<List<BookingResponse>>.Success(bookings)
        };
        var controller = new BookingsController(service);

        var action = await controller.GetBookings(21);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(bookings, ok.Value);
        Assert.Equal(21, service.LastClassSessionId);
        Assert.Equal(0, service.GetBookingsCalls);
    }

    [Fact]
    public async Task GetBookingsWithSessionFilterMapsForbidden()
    {
        var service = new FakeBookingsService
        {
            GetByClassSessionResult = new ServiceResult<List<BookingResponse>>(
                ServiceResultStatus.Forbidden,
                default,
                new ServiceError("Bookings cannot be viewed.", "Access is denied."))
        };
        var controller = new BookingsController(service);

        var action = await controller.GetBookings(21);

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status403Forbidden);
    }

    [Fact]
    public async Task GetBookingReturnsItemAndForwardsId()
    {
        var booking = Booking();
        var service = new FakeBookingsService
        {
            GetBookingResult = ServiceResult<BookingResponse>.Success(booking)
        };
        var controller = new BookingsController(service);

        var action = await controller.GetBooking(31);

        var ok = Assert.IsType<OkObjectResult>(action.Result);
        Assert.Same(booking, ok.Value);
        Assert.Equal(31, service.LastBookingId);
    }

    [Fact]
    public async Task GetBookingMapsNotFound()
    {
        var service = new FakeBookingsService
        {
            GetBookingResult = ServiceResult<BookingResponse>.NotFound(
                "Booking not found.",
                "A booking with this id does not exist.")
        };
        var controller = new BookingsController(service);

        var action = await controller.GetBooking(404);

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status404NotFound);
    }

    [Fact]
    public async Task CreateBookingReturnsCreatedAtGetBookingAndForwardsRequest()
    {
        var booking = Booking();
        var request = new CreateBookingRequest { MemberId = 11, ClassSessionId = 21 };
        var service = new FakeBookingsService
        {
            CreateBookingResult = ServiceResult<BookingResponse>.Success(booking)
        };
        var controller = new BookingsController(service);

        var action = await controller.CreateBooking(request);

        var created = Assert.IsType<CreatedAtActionResult>(action.Result);
        Assert.Equal(nameof(BookingsController.GetBooking), created.ActionName);
        Assert.Equal(booking.Id, created.RouteValues?["id"]);
        Assert.Same(booking, created.Value);
        Assert.Same(request, service.LastCreateRequest);
    }

    [Fact]
    public async Task CreateBookingMapsConflict()
    {
        var service = new FakeBookingsService
        {
            CreateBookingResult = ServiceResult<BookingResponse>.Conflict(
                "Booking conflict.",
                "The member already has a booking.")
        };
        var controller = new BookingsController(service);

        var action = await controller.CreateBooking(new CreateBookingRequest());

        SchedulingControllerTestAssertions.Problem(
            action.Result,
            StatusCodes.Status409Conflict);
    }

    [Fact]
    public async Task UpdateBookingStatusReturnsNoContentAndForwardsArguments()
    {
        var request = new UpdateBookingStatusRequest { Status = "attended" };
        var service = new FakeBookingsService { UpdateStatusResult = ServiceResult.Success() };
        var controller = new BookingsController(service);

        var action = await controller.UpdateBookingStatus(31, request);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(31, service.LastUpdateBookingId);
        Assert.Same(request, service.LastUpdateRequest);
    }

    [Fact]
    public async Task UpdateBookingStatusMapsForbidden()
    {
        var service = new FakeBookingsService
        {
            UpdateStatusResult = ServiceResult.Forbidden(
                "Booking cannot be updated.",
                "Access is denied.")
        };
        var controller = new BookingsController(service);

        var action = await controller.UpdateBookingStatus(
            31,
            new UpdateBookingStatusRequest());

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status403Forbidden);
    }

    [Fact]
    public async Task CancelBookingReturnsNoContentAndForwardsId()
    {
        var service = new FakeBookingsService { CancelBookingResult = ServiceResult.Success() };
        var controller = new BookingsController(service);

        var action = await controller.CancelBooking(31);

        Assert.IsType<NoContentResult>(action);
        Assert.Equal(31, service.LastCancelBookingId);
    }

    [Fact]
    public async Task CancelBookingMapsConflict()
    {
        var service = new FakeBookingsService
        {
            CancelBookingResult = ServiceResult.Conflict(
                "Booking cannot be cancelled.",
                "The cancellation window is closed.")
        };
        var controller = new BookingsController(service);

        var action = await controller.CancelBooking(31);

        SchedulingControllerTestAssertions.Problem(
            action,
            StatusCodes.Status409Conflict);
    }

    private static BookingResponse Booking()
        => new()
        {
            Id = 31,
            MemberId = 11,
            MemberFirstName = "Ana",
            MemberLastName = "Horvat",
            ClassSessionId = 21,
            BookingSource = "self_service",
            ClassTypeId = 5,
            ClassTypeName = "Pilates",
            TrainerId = 8,
            TrainerFirstName = "Ivan",
            TrainerLastName = "Ivic",
            ClassSessionStartsAt = new DateTime(2026, 10, 13, 17, 0, 0, DateTimeKind.Utc),
            ClassSessionEndsAt = new DateTime(2026, 10, 13, 18, 0, 0, DateTimeKind.Utc),
            Status = "booked",
            BookedAt = new DateTime(2026, 10, 12, 12, 0, 0, DateTimeKind.Utc)
        };

    private sealed class FakeBookingsService : IBookingsService
    {
        public List<BookingResponse> GetBookingsResult { get; init; } = [];
        public ServiceResult<List<BookingResponse>> GetByClassSessionResult { get; init; } = null!;
        public ServiceResult<BookingResponse> GetBookingResult { get; init; } = null!;
        public ServiceResult<BookingResponse> CreateBookingResult { get; init; } = null!;
        public ServiceResult UpdateStatusResult { get; init; } = null!;
        public ServiceResult CancelBookingResult { get; init; } = null!;
        public int GetBookingsCalls { get; private set; }
        public long? LastClassSessionId { get; private set; }
        public long? LastBookingId { get; private set; }
        public CreateBookingRequest? LastCreateRequest { get; private set; }
        public long? LastUpdateBookingId { get; private set; }
        public UpdateBookingStatusRequest? LastUpdateRequest { get; private set; }
        public long? LastCancelBookingId { get; private set; }

        public Task<List<BookingResponse>> GetBookingsAsync()
        {
            GetBookingsCalls++;
            return Task.FromResult(GetBookingsResult);
        }

        public Task<ServiceResult<List<BookingResponse>>> GetBookingsByClassSessionIdAsync(
            long classSessionId)
        {
            LastClassSessionId = classSessionId;
            return Task.FromResult(GetByClassSessionResult);
        }

        public Task<ServiceResult<BookingResponse>> GetBookingAsync(long id)
        {
            LastBookingId = id;
            return Task.FromResult(GetBookingResult);
        }

        public Task<ServiceResult<BookingResponse>> CreateBookingAsync(
            CreateBookingRequest request)
        {
            LastCreateRequest = request;
            return Task.FromResult(CreateBookingResult);
        }

        public Task<ServiceResult> UpdateBookingStatusAsync(
            long id,
            UpdateBookingStatusRequest request)
        {
            LastUpdateBookingId = id;
            LastUpdateRequest = request;
            return Task.FromResult(UpdateStatusResult);
        }

        public Task<ServiceResult> CancelBookingAsync(long id)
        {
            LastCancelBookingId = id;
            return Task.FromResult(CancelBookingResult);
        }
    }
}
