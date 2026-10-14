import '../../../../core/error/result.dart';
import '../repositories/recurring_schedules_repository.dart';

class AddFixedScheduleMember {
  const AddFixedScheduleMember(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<void>> call({
    required int memberId,
    required int scheduleId,
    required DateTime startsOn,
  }) => _repository.addFixedScheduleMember(
    memberId: memberId,
    scheduleId: scheduleId,
    startsOn: startsOn,
  );
}
