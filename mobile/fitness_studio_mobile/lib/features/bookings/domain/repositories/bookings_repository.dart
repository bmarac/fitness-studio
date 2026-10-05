import '../../../../core/error/result.dart';
import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<Result<void>> cancelBooking(int id);

  Future<Result<void>> cancelFixedSchedule({
    required int id,
    required DateTime effectiveFrom,
  });

  Future<Result<void>> updateBookingStatus({
    required int id,
    required String status,
  });

  Future<Result<List<Booking>>> getBookingsByClassSessionId(int classSessionId);

  Future<Result<Booking>> createBooking({
    required int memberId,
    required int classSessionId,
  });
}
