import '../../../../core/error/result.dart';
import '../entities/recurring_schedule_draft.dart';
import '../entities/schedule_form_data.dart';
import '../entities/recurring_schedule.dart';
import '../entities/trainer_option.dart';
import '../entities/fixed_schedule_member.dart';
import '../entities/schedule_member_option.dart';

abstract class RecurringSchedulesRepository {
  Future<Result<ScheduleFormData>> getFormData();

  Future<Result<List<TrainerOption>>> getTrainers();

  Future<Result<List<RecurringSchedule>>> getSchedules();

  Future<Result<List<FixedScheduleMember>>> getScheduleMembers(int scheduleId);

  Future<Result<List<ScheduleMemberOption>>> getMemberOptions(
    int scheduleId,
    DateTime startsOn,
  );

  Future<Result<void>> addFixedScheduleMember({
    required int memberId,
    required int scheduleId,
    required DateTime startsOn,
  });

  Future<Result<void>> moveFixedScheduleMember({
    required int assignmentId,
    required int targetScheduleId,
  });

  Future<Result<void>> createSchedule(RecurringScheduleDraft draft);

  Future<Result<void>> changeScheduleStatus({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  });
}
