import '../../../../core/error/result.dart';
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class GetClassSessionBookings {
  const GetClassSessionBookings(this._repository);

  final BookingsRepository _repository;

  Future<Result<List<Booking>>> call(int classSessionId) {
    return _repository.getBookingsByClassSessionId(classSessionId);
  }
}
