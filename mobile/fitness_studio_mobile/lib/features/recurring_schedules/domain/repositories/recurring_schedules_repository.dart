import '../../../../core/error/result.dart';
import '../entities/recurring_schedule_draft.dart';
import '../entities/schedule_form_data.dart';

abstract class RecurringSchedulesRepository {
  Future<Result<ScheduleFormData>> getFormData();

  Future<Result<void>> createSchedule(RecurringScheduleDraft draft);
}
