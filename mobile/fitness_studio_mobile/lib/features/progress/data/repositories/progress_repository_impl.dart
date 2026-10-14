import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/member_progress.dart';
import '../../domain/entities/progress_management.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_data_source.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._remoteDataSource);

  final ProgressRemoteDataSource _remoteDataSource;

  @override
  Future<Result<MemberProgress>> getMemberProgress(int memberId) async {
    try {
      return Success(await _remoteDataSource.getMemberProgress(memberId));
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readProgress));
    }
  }

  @override
  Future<Result<List<ProgressMember>>> getMembers() =>
      _guard(_remoteDataSource.getMembers, FailureKind.readMembers);

  @override
  Future<Result<List<MeasurementParameter>>> getMeasurementParameters() =>
      _guard(
        _remoteDataSource.getMeasurementParameters,
        FailureKind.readMeasurementParameters,
      );

  @override
  Future<Result<List<MeasurementParameter>>> saveMeasurementParameters(
    List<MeasurementParameter> parameters,
  ) => _guard(
    () => _remoteDataSource.saveMeasurementParameters(parameters),
    FailureKind.readMeasurementParameters,
  );

  @override
  Future<Result<void>> createMeasurement(
    int memberId,
    NewMeasurement measurement,
  ) => _guard(
    () => _remoteDataSource.createMeasurement(memberId, measurement),
    FailureKind.saveMeasurement,
  );

  Future<Result<T>> _guard<T>(
    Future<T> Function() action,
    FailureKind formatFailure,
  ) async {
    try {
      return Success(await action());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return FailureResult(Failure(formatFailure));
    }
  }
}
