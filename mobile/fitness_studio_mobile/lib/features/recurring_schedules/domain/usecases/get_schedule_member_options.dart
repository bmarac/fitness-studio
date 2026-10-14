import '../../../../core/error/result.dart';
import '../entities/schedule_member_option.dart';
import '../repositories/recurring_schedules_repository.dart';

class GetScheduleMemberOptions {
  const GetScheduleMemberOptions(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<List<ScheduleMemberOption>>> call(
    int scheduleId,
    DateTime startsOn,
  ) => _repository.getMemberOptions(scheduleId, startsOn);
}
