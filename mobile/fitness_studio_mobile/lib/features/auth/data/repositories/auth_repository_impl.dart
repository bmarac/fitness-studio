import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      final session = await _localDataSource.readSession();

      if (session == null) {
        return const Success<AuthSession?>(null);
      }

      if (!session.expiresAt.isAfter(DateTime.now().toUtc())) {
        await _localDataSource.clearSession();
        return const Success<AuthSession?>(null);
      }

      return Success<AuthSession?>(session);
    } on AuthStorageException {
      return const FailureResult(
        Failure(message: 'Nije moguce ucitati spremljenu prijavu.'),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _localDataSource.clearSession();
      return const Success<void>(null);
    } on AuthStorageException {
      return const FailureResult(
        Failure(message: 'Odjava trenutno nije moguca. Pokusaj ponovno.'),
      );
    }
  }

  @override
  Future<Result<AuthSession>> login({
    required int studioId,
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.login(
        studioId: studioId,
        email: email.trim().toLowerCase(),
        password: password,
      );
      await _localDataSource.saveSession(session);

      return Success(session);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati odgovor za prijavu.'),
      );
    } on AuthStorageException {
      return const FailureResult(
        Failure(message: 'Nije moguce sigurno spremiti prijavu.'),
      );
    }
  }
}
