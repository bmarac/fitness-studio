import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/entities/recurring_schedule.dart';
import '../../domain/entities/schedule_form_data.dart';
import '../../domain/entities/trainer_option.dart';
import '../../domain/entities/fixed_schedule_member.dart';
import '../../domain/entities/schedule_member_option.dart';
import '../../domain/entities/update_recurring_schedule_draft.dart';
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
  Future<Result<List<FixedScheduleMember>>> getScheduleMembers(
    int scheduleId,
  ) async {
    try {
      return Success(await _remoteDataSource.getScheduleMembers(scheduleId));
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readMembers));
    }
  }

  @override
  Future<Result<List<ScheduleMemberOption>>> getMemberOptions(
    int scheduleId,
    DateTime startsOn,
  ) async {
    try {
      return Success(
        await _remoteDataSource.getMemberOptions(scheduleId, startsOn),
      );
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readMembers));
    }
  }

  @override
  Future<Result<void>> addFixedScheduleMember({
    required int memberId,
    required int scheduleId,
    required DateTime startsOn,
  }) async {
    try {
      await _remoteDataSource.addFixedScheduleMember(
        memberId: memberId,
        scheduleId: scheduleId,
        startsOn: startsOn,
      );
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }

  @override
  Future<Result<void>> moveFixedScheduleMember({
    required int assignmentId,
    required int targetScheduleId,
  }) async {
    try {
      await _remoteDataSource.moveFixedScheduleMember(
        assignmentId: assignmentId,
        targetScheduleId: targetScheduleId,
      );
      return const Success<void>(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
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
  Future<Result<void>> updateSchedule(
    int id,
    UpdateRecurringScheduleDraft draft,
  ) async {
    try {
      await _remoteDataSource.updateSchedule(id, draft);
      return const Success<void>(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
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
