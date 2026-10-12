import '../../../../core/error/result.dart';
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class GetBookings {
  const GetBookings(this._repository);

  final BookingsRepository _repository;

  Future<Result<List<Booking>>> call() => _repository.getBookings();
}
