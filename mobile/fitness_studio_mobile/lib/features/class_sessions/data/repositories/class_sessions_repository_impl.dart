import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/repositories/class_sessions_repository.dart';
import '../datasources/class_sessions_remote_data_source.dart';

class ClassSessionsRepositoryImpl implements ClassSessionsRepository {
  const ClassSessionsRepositoryImpl(this._remoteDataSource);

  final ClassSessionsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<ClassSession>>> getClassSessions() async {
    try {
      final classSessions = await _remoteDataSource.getClassSessions();

      return Success(classSessions);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
    }
  }

  @override
  Future<Result<List<ClassSession>>> getMyClassSessions() async {
    try {
      final classSessions = await _remoteDataSource.getMyClassSessions();
      return Success(classSessions);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
    }
  }

  @override
  Future<Result<ClassSession>> getClassSession(int id) async {
    try {
      final classSession = await _remoteDataSource.getClassSession(id);

      return Success(classSession);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
    }
  }

  @override
  Future<Result<void>> cancelClassSession(int id) async {
    try {
      await _remoteDataSource.cancelClassSession(id);
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    }
  }
}
