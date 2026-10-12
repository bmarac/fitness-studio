import '../../../../core/error/result.dart';
import '../repositories/recurring_schedules_repository.dart';

class ChangeRecurringScheduleStatus {
  const ChangeRecurringScheduleStatus(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<void>> call({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  }) {
    return _repository.changeScheduleStatus(
      id: id,
      action: action,
      effectiveFrom: effectiveFrom,
    );
  }
}
