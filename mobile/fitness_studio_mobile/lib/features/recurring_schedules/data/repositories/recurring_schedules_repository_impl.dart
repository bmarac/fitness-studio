import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/entities/schedule_form_data.dart';
import '../../domain/repositories/recurring_schedules_repository.dart';
import '../datasources/recurring_schedules_remote_data_source.dart';

class RecurringSchedulesRepositoryImpl implements RecurringSchedulesRepository {
  const RecurringSchedulesRepositoryImpl(this._remoteDataSource);

  final RecurringSchedulesRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ScheduleFormData>> getFormData() async {
    try {
      final classTypes = await _remoteDataSource.getClassTypes();
      final trainers = await _remoteDataSource.getTrainers();

      return Success(
        ScheduleFormData(classTypes: classTypes, trainers: trainers),
      );
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke za novi termin.'),
      );
    }
  }

  @override
  Future<Result<void>> createSchedule(RecurringScheduleDraft draft) async {
    try {
      await _remoteDataSource.createSchedule(draft);
      return const Success<void>(null);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati odgovor za novi termin.'),
      );
    }
  }
}
