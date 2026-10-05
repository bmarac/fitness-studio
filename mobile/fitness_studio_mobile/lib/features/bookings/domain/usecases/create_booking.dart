import '../../../../core/error/result.dart';
import '../entities/booking.dart';
import '../repositories/bookings_repository.dart';

class CreateBooking {
  const CreateBooking(this._repository);

  final BookingsRepository _repository;

  Future<Result<Booking>> call({
    required int memberId,
    required int classSessionId,
  }) {
    return _repository.createBooking(
      memberId: memberId,
      classSessionId: classSessionId,
    );
  }
}
