import '../../../../core/error/result.dart';
import '../repositories/bookings_repository.dart';

class CancelFixedSchedule {
  const CancelFixedSchedule(this._repository);

  final BookingsRepository _repository;

  Future<Result<void>> call({
    required int id,
    required DateTime effectiveFrom,
  }) {
    return _repository.cancelFixedSchedule(
      id: id,
      effectiveFrom: effectiveFrom,
    );
  }
}
