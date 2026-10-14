import '../../../../core/error/result.dart';
import '../entities/update_recurring_schedule_draft.dart';
import '../repositories/recurring_schedules_repository.dart';

class UpdateRecurringSchedule {
  const UpdateRecurringSchedule(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<void>> call(int id, UpdateRecurringScheduleDraft draft) =>
      _repository.updateSchedule(id, draft);
}
