import '../../../../core/error/result.dart';
import '../repositories/bookings_repository.dart';

class UpdateBookingStatus {
  const UpdateBookingStatus(this._repository);

  final BookingsRepository _repository;

  Future<Result<void>> call({required int id, required String status}) {
    return _repository.updateBookingStatus(id: id, status: status);
  }
}
