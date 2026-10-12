import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/entities/recurring_schedule.dart';
import '../../domain/entities/schedule_form_data.dart';
import '../../domain/entities/trainer_option.dart';
import '../../domain/repositories/recurring_schedules_repository.dart';
import '../datasources/recurring_schedules_remote_data_source.dart';

class RecurringSchedulesRepositoryImpl implements RecurringSchedulesRepository {
  const RecurringSchedulesRepositoryImpl(this._remoteDataSource);

  final RecurringSchedulesRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TrainerOption>>> getTrainers() async {
    try {
      return Success(await _remoteDataSource.getTrainers());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readTrainers));
    }
  }

  @override
  Future<Result<List<RecurringSchedule>>> getSchedules() async {
    try {
      return Success(await _remoteDataSource.getSchedules());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readSchedules));
    }
  }

  @override
  Future<Result<ScheduleFormData>> getFormData() async {
    try {
      final classTypes = await _remoteDataSource.getClassTypes();
      final trainers = await _remoteDataSource.getTrainers();

      return Success(
        ScheduleFormData(classTypes: classTypes, trainers: trainers),
      );
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readScheduleForm));
    }
  }

  @override
  Future<Result<void>> createSchedule(RecurringScheduleDraft draft) async {
    try {
      await _remoteDataSource.createSchedule(draft);
      return const Success<void>(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readScheduleResponse));
    }
  }

  @override
  Future<Result<void>> changeScheduleStatus({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  }) async {
    try {
      await _remoteDataSource.changeScheduleStatus(
        id: id,
        action: action,
        effectiveFrom: effectiveFrom,
      );
      return const Success<void>(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }
}
