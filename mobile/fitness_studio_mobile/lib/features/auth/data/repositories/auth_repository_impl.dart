import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/notifications/push_notifications_service.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/studio_membership.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/account_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this._remote,
    this._local, [
    this._pushNotifications,
  ]);
  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final PushNotificationsService? _pushNotifications;

  @override
  Future<Result<AccountSession>> login({
    required String email,
    required String password,
  }) => _account(
    () => _remote.login(email: email.trim().toLowerCase(), password: password),
  );

  @override
  Future<Result<AccountSession>> register({
    required String email,
    required String password,
  }) => _account(
    () =>
        _remote.register(email: email.trim().toLowerCase(), password: password),
  );

  Future<Result<AccountSession>> _account(
    Future<AccountSessionModel> Function() action,
  ) async {
    try {
      final session = await action();
      await _local.saveAccountSession(session);
      await _pushNotifications?.registerCurrentToken();
      return Success(session);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.loginResponse));
    } on AuthStorageException {
      return const FailureResult(Failure(FailureKind.saveSession));
    }
  }

  @override
  Future<Result<AuthSession>> selectStudio(int studioId) async {
    try {
      final session = await _remote.selectStudio(studioId);
      await _local.saveSession(session);
      await _local.saveLastStudioId(studioId);
      await _pushNotifications?.registerCurrentToken();
      return Success(session);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.loginResponse));
    } on AuthStorageException {
      return const FailureResult(Failure(FailureKind.saveSession));
    }
  }

  @override
  Future<Result<StudioLookup>> lookupStudio(String code) =>
      _guard(() => _remote.lookupStudio(code.trim().toUpperCase()));

  @override
  Future<Result<StudioMembership>> joinStudio({
    required String code,
    String? firstName,
    String? lastName,
  }) async {
    final result = await _guard(
      () => _remote.joinStudio(
        code: code.trim().toUpperCase(),
        firstName: firstName?.trim(),
        lastName: lastName?.trim(),
      ),
    );
    if (result case Success(value: final membership)) {
      final account = await _local.readAccountSession();
      if (account != null &&
          !account.studios.any(
            (item) => item.studioId == membership.studioId,
          )) {
        await _local.saveAccountSession(
          AccountSessionModel(
            accessToken: account.accessToken,
            expiresAt: account.expiresAt,
            userId: account.userId,
            email: account.email,
            studios: [...account.studios, membership],
          ),
        );
      }
    }
    return result;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.loginResponse));
    }
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    try {
      final session = await _local.readSession();
      if (session == null ||
          !session.expiresAt.isAfter(DateTime.now().toUtc())) {
        return const Success(null);
      }
      await _pushNotifications?.registerCurrentToken();
      return Success(session);
    } on AuthStorageException {
      return const FailureResult(Failure(FailureKind.restoreSession));
    }
  }

  @override
  Future<Result<AccountSession?>> restoreAccountSession() async {
    try {
      final session = await _local.readAccountSession();
      if (session == null ||
          !session.expiresAt.isAfter(DateTime.now().toUtc())) {
        return const Success(null);
      }
      return Success(session);
    } on AuthStorageException {
      return const FailureResult(Failure(FailureKind.restoreSession));
    }
  }

  @override
  Future<int?> readLastStudioId() => _local.readLastStudioId();

  @override
  Future<Result<void>> logout() async {
    try {
      await _pushNotifications?.unregisterCurrentToken();
      await _local.clearSession();
      return const Success(null);
    } on AuthStorageException {
      return const FailureResult(Failure(FailureKind.logout));
    }
  }
}
