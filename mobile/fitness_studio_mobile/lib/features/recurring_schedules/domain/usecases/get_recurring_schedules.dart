import '../../../../core/error/result.dart';
import '../entities/recurring_schedule.dart';
import '../repositories/recurring_schedules_repository.dart';

class GetRecurringSchedules {
  const GetRecurringSchedules(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<List<RecurringSchedule>>> call() {
    return _repository.getSchedules();
  }
}
