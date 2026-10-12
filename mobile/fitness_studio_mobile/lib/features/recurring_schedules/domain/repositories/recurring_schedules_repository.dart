import '../../../../core/error/result.dart';
import '../entities/recurring_schedule_draft.dart';
import '../entities/schedule_form_data.dart';
import '../entities/recurring_schedule.dart';
import '../entities/trainer_option.dart';

abstract class RecurringSchedulesRepository {
  Future<Result<ScheduleFormData>> getFormData();

  Future<Result<List<TrainerOption>>> getTrainers();

  Future<Result<List<RecurringSchedule>>> getSchedules();

  Future<Result<void>> createSchedule(RecurringScheduleDraft draft);

  Future<Result<void>> changeScheduleStatus({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  });
}
