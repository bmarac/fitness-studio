using AutoMapper;
using AutoMapper.QueryableExtensions;
using FitnessStudio.Api.Data;
using FitnessStudio.Api.Domain.Auth;
using FitnessStudio.Api.Domain.Bookings;
using FitnessStudio.Api.Domain.ClassSessions;
using FitnessStudio.Api.Domain.Members;
using FitnessStudio.Api.Dtos.Bookings;
using FitnessStudio.Api.Entities;
using FitnessStudio.Api.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FitnessStudio.Api.Services.Bookings;

public class BookingsService : IBookingsService
{
    private readonly AutoMapper.IConfigurationProvider _configurationProvider;
    private readonly ICurrentUserContext _currentUser;
    private readonly FitnessStudioDbContext _dbContext;
    private readonly IMapper _mapper;

    public BookingsService(
        FitnessStudioDbContext dbContext,
        IMapper mapper,
        ICurrentUserContext currentUser)
    {
        _dbContext = dbContext;
        _mapper = mapper;
        _currentUser = currentUser;
        _configurationProvider = mapper.ConfigurationProvider;
    }

    public Task<List<BookingResponse>> GetBookingsAsync()
    {
        var query = _dbContext.Bookings
            .AsNoTracking()
            .Where(booking => booking.StudioId == _currentUser.StudioId);

        if (_currentUser.IsMemberOnly)
        {
            query = query.Where(booking => booking.MemberId == GetCurrentMemberId());
        }

        return query
            .OrderByDescending(booking => booking.BookedAt)
            .ProjectTo<BookingResponse>(_configurationProvider)
            .ToListAsync();
    }

    public async Task<int> GetCurrentMemberUsageAsync(DateOnly startsOn, DateOnly endsOn)
    {
        if (!_currentUser.MemberId.HasValue)
        {
            return 0;
        }

        var timezoneId = await _dbContext.Studios
            .Where(studio => studio.Id == _currentUser.StudioId)
            .Select(studio => studio.Timezone)
            .SingleAsync();
        var timezone = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
        var startsAtUtc = TimeZoneInfo.ConvertTimeToUtc(
            startsOn.ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified),
            timezone);
        var endsAtUtcExclusive = TimeZoneInfo.ConvertTimeToUtc(
            endsOn.AddDays(1).ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified),
            timezone);

        return await _dbContext.Bookings.CountAsync(booking =>
            booking.StudioId == _currentUser.StudioId
            && booking.MemberId == _currentUser.MemberId.Value
            && (booking.Status == BookingStatuses.Booked
                || booking.Status == BookingStatuses.Attended
                || booking.Status == BookingStatuses.NoShow)
            && booking.ClassSession.StartsAt >= startsAtUtc
            && booking.ClassSession.StartsAt < endsAtUtcExclusive);
    }

    public async Task<ServiceResult<List<BookingResponse>>> GetBookingsByClassSessionIdAsync(
        long classSessionId)
    {
        var classSession = await _dbContext.ClassSessions
            .AsNoTracking()
            .FirstOrDefaultAsync(item =>
                item.Id == classSessionId
                && item.StudioId == _currentUser.StudioId);

        if (classSession is null)
        {
            return ServiceResult<List<BookingResponse>>.NotFound(
                "Class session not found.",
                "A class session with this id does not exist.");
        }

        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == classSession.TrainerId;

        if (!isAdmin && !isAssignedTrainer)
        {
            return new ServiceResult<List<BookingResponse>>(
                ServiceResultStatus.Forbidden,
                default,
                new ServiceError(
                    "Bookings cannot be viewed.",
                    "Trainers can view bookings only for their own class sessions."));
        }

        var bookings = await _dbContext.Bookings
            .AsNoTracking()
            .Where(booking =>
                booking.StudioId == _currentUser.StudioId
                && booking.ClassSessionId == classSessionId
                && booking.Status != BookingStatuses.Cancelled)
            .OrderBy(booking => booking.Member.LastName)
            .ThenBy(booking => booking.Member.FirstName)
            .ProjectTo<BookingResponse>(_configurationProvider)
            .ToListAsync();

        if (classSession.RecurringScheduleId.HasValue)
        {
            var memberIds = bookings
                .Where(booking => booking.BookingSource == "fixed_schedule")
                .Select(booking => booking.MemberId)
                .ToHashSet();

            var fixedSchedules = await _dbContext.MemberFixedSchedules
                .AsNoTracking()
                .Where(schedule =>
                    schedule.StudioId == _currentUser.StudioId
                    && schedule.RecurringScheduleId == classSession.RecurringScheduleId.Value
                    && memberIds.Contains(schedule.MemberId)
                    && schedule.StartsOn <= DateOnly.FromDateTime(classSession.StartsAt)
                    && (!schedule.EndsOn.HasValue
                        || schedule.EndsOn.Value >= DateOnly.FromDateTime(classSession.StartsAt)))
                .OrderByDescending(schedule => schedule.StartsOn)
                .ToListAsync();

            foreach (var booking in bookings.Where(item => item.BookingSource == "fixed_schedule"))
            {
                booking.MemberFixedScheduleId = fixedSchedules
                    .FirstOrDefault(schedule => schedule.MemberId == booking.MemberId)
                    ?.Id;
            }
        }

        return ServiceResult<List<BookingResponse>>.Success(bookings);
    }

    public async Task<ServiceResult<BookingResponse>> GetBookingAsync(long id)
    {
        var booking = await _dbContext.Bookings
            .AsNoTracking()
            .Where(booking =>
                booking.Id == id
                && booking.StudioId == _currentUser.StudioId
                && (!_currentUser.IsMemberOnly || booking.MemberId == GetCurrentMemberId()))
            .ProjectTo<BookingResponse>(_configurationProvider)
            .FirstOrDefaultAsync();

        if (booking is null)
        {
            return ServiceResult<BookingResponse>.NotFound(
                "Booking not found.",
                "A booking with this id does not exist.");
        }

        return ServiceResult<BookingResponse>.Success(booking);
    }

    public async Task<ServiceResult<BookingResponse>> CreateBookingAsync(CreateBookingRequest request)
    {
        var memberId = _currentUser.IsMemberOnly
            ? GetCurrentMemberId()
            : request.MemberId;

        var validationResult = await ValidateBookingCanBeCreatedAsync(memberId, request.ClassSessionId);

        if (validationResult.Status != ServiceResultStatus.Success)
        {
            return new ServiceResult<BookingResponse>(validationResult.Status, default, validationResult.Error);
        }

        var booking = _mapper.Map<Booking>(request);
        booking.StudioId = _currentUser.StudioId;
        booking.MemberId = memberId;
        booking.BookingSource = _currentUser.IsMemberOnly
            ? "self_service"
            : "admin";
        booking.Status = BookingStatuses.Booked;
        booking.BookedAt = DateTime.UtcNow;
        booking.CreatedAt = DateTime.UtcNow;
        booking.UpdatedAt = DateTime.UtcNow;

        _dbContext.Bookings.Add(booking);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult<BookingResponse>.Conflict(
                "Booking already exists.",
                "This member already has an active booking for this class session.");
        }

        return await GetBookingAsync(booking.Id);
    }

    public async Task<ServiceResult> UpdateBookingStatusAsync(long id, UpdateBookingStatusRequest request)
    {
        var booking = await _dbContext.Bookings
            .Include(booking => booking.ClassSession)
            .FirstOrDefaultAsync(booking =>
                booking.Id == id && booking.StudioId == _currentUser.StudioId);

        if (booking is null)
        {
            return ServiceResult.NotFound(
                "Booking not found.",
                "A booking with this id does not exist.");
        }

        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == booking.ClassSession.TrainerId;

        if (!isAdmin && !isAssignedTrainer)
        {
            return ServiceResult.Forbidden(
                "Booking status cannot be updated.",
                "Trainers can update attendance only for their own class sessions.");
        }

        var status = NormalizeValue(request.Status);

        if (status == BookingStatuses.Booked)
        {
            var capacityResult = await ValidateBookingCapacityAsync(booking.ClassSessionId, ignoredBookingId: booking.Id);

            if (capacityResult.Status != ServiceResultStatus.Success)
            {
                return capacityResult;
            }
        }

        ApplyStatus(booking, status);

        try
        {
            await _dbContext.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return ServiceResult.Conflict(
                "Booking status cannot be updated.",
                "This status change conflicts with existing booking rules.");
        }

        return ServiceResult.Success();
    }

    public async Task<ServiceResult> CancelBookingAsync(long id)
    {
        var booking = await _dbContext.Bookings
            .Include(booking => booking.ClassSession)
            .FirstOrDefaultAsync(booking =>
            booking.Id == id
            && booking.StudioId == _currentUser.StudioId);

        if (booking is null)
        {
            return ServiceResult.NotFound(
                "Booking not found.",
                "A booking with this id does not exist.");
        }

        var isOwner = _currentUser.IsInRole(AuthRoles.Member)
            && _currentUser.MemberId == booking.MemberId;
        var isAdmin = _currentUser.IsInRole(AuthRoles.Admin);
        var isAssignedTrainer = _currentUser.IsInRole(AuthRoles.Trainer)
            && _currentUser.TrainerId == booking.ClassSession.TrainerId;

        if (!isOwner && !isAdmin && !isAssignedTrainer)
        {
            return ServiceResult.Forbidden(
                "Booking cannot be cancelled.",
                "Trainers can cancel bookings only for their own class sessions.");
        }

        if (booking.Status == BookingStatuses.Cancelled)
        {
            return ServiceResult.Success();
        }

        ApplyStatus(booking, BookingStatuses.Cancelled);
        await _dbContext.SaveChangesAsync();

        return ServiceResult.Success();
    }

    private async Task<ServiceResult> ValidateBookingCanBeCreatedAsync(long memberId, long classSessionId)
    {
        var member = await _dbContext.Members
            .AsNoTracking()
            .FirstOrDefaultAsync(member =>
                member.Id == memberId && member.StudioId == _currentUser.StudioId);

        if (member is null)
        {
            return ServiceResult.Conflict(
                "Member does not exist.",
                "Booking must reference an existing member.");
        }

        if (member.Status != MemberStatuses.Active)
        {
            return ServiceResult.Conflict(
                "Member is not active.",
                "Only active members can book class sessions.");
        }

        var classSession = await _dbContext.ClassSessions
            .AsNoTracking()
            .FirstOrDefaultAsync(classSession =>
                classSession.Id == classSessionId
                && classSession.StudioId == _currentUser.StudioId);

        if (classSession is null)
        {
            return ServiceResult.Conflict(
                "Class session does not exist.",
                "Booking must reference an existing class session.");
        }

        if (classSession.Status != ClassSessionStatuses.Scheduled)
        {
            return ServiceResult.Conflict(
                "Class session is not available.",
                "Only scheduled class sessions can be booked.");
        }

        if (classSession.EndsAt <= DateTime.UtcNow)
        {
            return ServiceResult.Conflict(
                "Class session has already ended.",
                "Past class sessions cannot be booked.");
        }

        if (await ActiveBookingExistsAsync(memberId, classSessionId))
        {
            return ServiceResult.Conflict(
                "Booking already exists.",
                "This member already has an active booking for this class session.");
        }

        return await ValidateBookingCapacityAsync(classSessionId);
    }

    private async Task<ServiceResult> ValidateBookingCapacityAsync(long classSessionId, long? ignoredBookingId = null)
    {
        var classSession = await _dbContext.ClassSessions
            .AsNoTracking()
            .FirstAsync(classSession =>
                classSession.Id == classSessionId
                && classSession.StudioId == _currentUser.StudioId);

        var bookedCount = await _dbContext.Bookings.CountAsync(booking =>
            booking.StudioId == _currentUser.StudioId
            && booking.ClassSessionId == classSessionId
            && BookingStatuses.CapacityCounting.Contains(booking.Status)
            && (!ignoredBookingId.HasValue || booking.Id != ignoredBookingId.Value));

        if (bookedCount >= classSession.Capacity)
        {
            return ServiceResult.Conflict(
                "Class session is full.",
                "This class session has reached its booking capacity.");
        }

        return ServiceResult.Success();
    }

    private Task<bool> ActiveBookingExistsAsync(long memberId, long classSessionId)
    {
        return _dbContext.Bookings.AnyAsync(booking =>
            booking.StudioId == _currentUser.StudioId
            && booking.MemberId == memberId
            && booking.ClassSessionId == classSessionId
            && BookingStatuses.Active.Contains(booking.Status));
    }

    private static void ApplyStatus(Booking booking, string status)
    {
        booking.Status = status;
        booking.UpdatedAt = DateTime.UtcNow;

        if (status == BookingStatuses.Cancelled)
        {
            booking.CancelledAt = DateTime.UtcNow;
            return;
        }

        if (status == BookingStatuses.Attended)
        {
            booking.AttendedAt = DateTime.UtcNow;
        }

        if (status == BookingStatuses.Booked)
        {
            booking.CancelledAt = null;
            booking.AttendedAt = null;
        }
    }

    private static string NormalizeValue(string value)
    {
        return value.ToLowerInvariant();
    }

    private long GetCurrentMemberId()
    {
        return _currentUser.MemberId
            ?? throw new InvalidOperationException("Authenticated member is missing the member_id claim.");
    }
}
