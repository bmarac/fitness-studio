import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/entities/class_session_workouts_page.dart';
import '../../domain/repositories/class_sessions_repository.dart';
import '../datasources/class_sessions_remote_data_source.dart';

class ClassSessionsRepositoryImpl implements ClassSessionsRepository {
  const ClassSessionsRepositoryImpl(this._remoteDataSource);

  final ClassSessionsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ClassSession>>> getClassSessions({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final classSessions = await _remoteDataSource.getClassSessions(
        from: from,
        to: to,
      );

      return Success(classSessions);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  @override
  Future<Result<List<ClassSession>>> getMyClassSessions() async {
    try {
      final classSessions = await _remoteDataSource.getMyClassSessions();
      return Success(classSessions);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  @override
  Future<Result<ClassSessionWorkoutsPage>> getWorkoutClassSessions({
    required String filter,
    required int page,
    required int pageSize,
    int? trainerId,
  }) async {
    try {
      final workouts = await _remoteDataSource.getWorkoutClassSessions(
        filter: filter,
        page: page,
        pageSize: pageSize,
        trainerId: trainerId,
      );
      return Success(workouts);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  @override
  Future<Result<ClassSession>> getClassSession(int id) async {
    try {
      final classSession = await _remoteDataSource.getClassSession(id);

      return Success(classSession);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  @override
  Future<Result<void>> cancelClassSession(int id) async {
    try {
      await _remoteDataSource.cancelClassSession(id);
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }
}
