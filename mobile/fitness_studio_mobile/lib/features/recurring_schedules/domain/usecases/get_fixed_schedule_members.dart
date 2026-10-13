import '../../../../core/error/result.dart';
import '../entities/fixed_schedule_member.dart';
import '../repositories/recurring_schedules_repository.dart';

class GetFixedScheduleMembers {
  const GetFixedScheduleMembers(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<List<FixedScheduleMember>>> call(int scheduleId) =>
      _repository.getScheduleMembers(scheduleId);
}
