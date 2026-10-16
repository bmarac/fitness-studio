import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/auth/refreshable_access_token_provider.dart';
import '../../../../core/config/app_config.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/account_session_model.dart';
import '../models/auth_session_model.dart';

class AuthSessionChange {
  const AuthSessionChange({this.account, this.studio, this.expired = false});

  final AccountSessionModel? account;
  final AuthSessionModel? studio;
  final bool expired;
}

class AuthSessionCoordinator implements RefreshableAccessTokenProvider {
  AuthSessionCoordinator({
    required AppConfig config,
    required AuthLocalDataSource localDataSource,
    Dio? authDio,
    DateTime Function()? now,
  }) : _local = localDataSource,
       _now = now ?? (() => DateTime.now().toUtc()),
       _authDio =
           authDio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           );

  static const _refreshWindow = Duration(seconds: 60);

  final AuthLocalDataSource _local;
  final Dio _authDio;
  final DateTime Function() _now;
  final _changes = StreamController<AuthSessionChange>.broadcast();
  Future<String?>? _refreshing;

  Stream<AuthSessionChange> get changes => _changes.stream;

  @override
  Future<String?> getAccessToken() async {
    final studio = await _local.readSession();
    final account = await _local.readAccountSession();
    if (studio == null && account == null) return null;
    final activeAccessToken = studio?.accessToken ?? account!.accessToken;
    final activeExpiresAt = studio?.expiresAt ?? account!.expiresAt;

    final now = _now();
    if (activeExpiresAt.isAfter(now.add(_refreshWindow))) {
      return activeAccessToken;
    }
    if (!_canRefresh(account, now)) {
      if (activeExpiresAt.isAfter(now)) return activeAccessToken;
      await _expireSession();
      return null;
    }
    return _refresh(studio: studio, account: account!);
  }

  @override
  Future<String?> forceRefreshAccessToken({String? rejectedAccessToken}) async {
    final studio = await _local.readSession();
    final account = await _local.readAccountSession();
    final currentToken = studio?.accessToken ?? account?.accessToken;
    final currentExpiry = studio?.expiresAt ?? account?.expiresAt;
    if (rejectedAccessToken != null &&
        currentToken != null &&
        currentToken != rejectedAccessToken &&
        currentExpiry!.isAfter(_now())) {
      return currentToken;
    }
    if (!_canRefresh(account, _now())) {
      await _expireSession();
      return null;
    }
    return _refresh(studio: studio, account: account!);
  }

  Future<String?> _refresh({
    required AuthSessionModel? studio,
    required AccountSessionModel account,
  }) {
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;
    final operation = _refreshInternal(studio: studio, account: account);
    _refreshing = operation;
    return operation.whenComplete(() {
      if (identical(_refreshing, operation)) _refreshing = null;
    });
  }

  Future<String?> _refreshInternal({
    required AuthSessionModel? studio,
    required AccountSessionModel account,
  }) async {
    try {
      final response = await _authDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': account.refreshToken},
      );
      final json = response.data;
      if (json == null) {
        throw const FormatException('Refresh response is empty.');
      }
      final refreshedAccount = AccountSessionModel.fromJson(json);
      await _local.saveAccountSession(
        refreshedAccount,
        clearStudioSession: false,
      );

      if (studio == null) {
        _changes.add(AuthSessionChange(account: refreshedAccount));
        return refreshedAccount.accessToken;
      }

      final selectedResponse = await _authDio.post<Map<String, dynamic>>(
        '/api/account/studios/${studio.user.studioId}/select',
        options: Options(
          headers: {'Authorization': 'Bearer ${refreshedAccount.accessToken}'},
        ),
      );
      final selectedJson = selectedResponse.data;
      if (selectedJson == null) {
        throw const FormatException('Studio session response is empty.');
      }
      final refreshedStudio = AuthSessionModel.fromJson(selectedJson);
      await _local.saveSession(refreshedStudio);
      _changes.add(
        AuthSessionChange(account: refreshedAccount, studio: refreshedStudio),
      );
      return refreshedStudio.accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _expireSession();
        return null;
      }
      if (error.response?.statusCode == 403 && studio != null) {
        await _local.clearStudioSession();
        final refreshed = await _local.readAccountSession();
        _changes.add(AuthSessionChange(account: refreshed));
        return refreshed?.accessToken;
      }
      rethrow;
    }
  }

  bool _canRefresh(AccountSessionModel? account, DateTime now) =>
      account?.refreshToken != null &&
      account?.refreshTokenExpiresAt?.isAfter(now) == true;

  Future<void> _expireSession() async {
    await _local.clearSession();
    _changes.add(const AuthSessionChange(expired: true));
  }

  Future<void> dispose() => _changes.close();
}
