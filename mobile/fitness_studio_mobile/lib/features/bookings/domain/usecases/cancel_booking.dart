import '../../../../core/error/result.dart';
import '../repositories/bookings_repository.dart';

class CancelBooking {
  const CancelBooking(this._repository);

  final BookingsRepository _repository;

  Future<Result<void>> call(int id) => _repository.cancelBooking(id);
}
