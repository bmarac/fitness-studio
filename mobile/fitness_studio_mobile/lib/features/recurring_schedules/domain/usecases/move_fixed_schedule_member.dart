import '../../../../core/error/result.dart';
import '../repositories/recurring_schedules_repository.dart';

class MoveFixedScheduleMember {
  const MoveFixedScheduleMember(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<void>> call({
    required int assignmentId,
    required int targetScheduleId,
  }) => _repository.moveFixedScheduleMember(
    assignmentId: assignmentId,
    targetScheduleId: targetScheduleId,
  );
}
