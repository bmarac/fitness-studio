import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/account_session_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/authenticated_user_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/services/auth_session_coordinator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 16, 10);
  late AuthLocalDataSource local;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    local = const AuthLocalDataSource(FlutterSecureStorage());
  });

  test(
    'refreshes account, reselects studio and persists rotated tokens',
    () async {
      await _saveExpiringSessions(local, now);
      final adapter = _RefreshAdapter();
      final coordinator = _coordinator(local, adapter, now);
      addTearDown(coordinator.dispose);

      final token = await coordinator.getAccessToken();

      expect(token, 'new-studio-token');
      expect(adapter.paths, [
        '/api/auth/refresh',
        '/api/account/studios/7/select',
      ]);
      expect(adapter.authorization, 'Bearer new-account-token');
      expect((await local.readAccountSession())?.refreshToken, 'refresh-2');
      expect((await local.readSession())?.accessToken, 'new-studio-token');
    },
  );

  test('parallel callers share one in-flight refresh', () async {
    await _saveExpiringSessions(local, now);
    final adapter = _RefreshAdapter(delay: const Duration(milliseconds: 20));
    final coordinator = _coordinator(local, adapter, now);
    addTearDown(coordinator.dispose);

    final tokens = await Future.wait([
      coordinator.forceRefreshAccessToken(),
      coordinator.forceRefreshAccessToken(),
      coordinator.forceRefreshAccessToken(),
    ]);

    expect(tokens, everyElement('new-studio-token'));
    expect(
      adapter.paths.where((path) => path == '/api/auth/refresh'),
      hasLength(1),
    );
  });

  test('late 401 from the previous token reuses the refreshed token', () async {
    await _saveExpiringSessions(local, now);
    final adapter = _RefreshAdapter();
    final coordinator = _coordinator(local, adapter, now);
    addTearDown(coordinator.dispose);
    await coordinator.forceRefreshAccessToken();

    final token = await coordinator.forceRefreshAccessToken(
      rejectedAccessToken: 'old-studio-token',
    );

    expect(token, 'new-studio-token');
    expect(
      adapter.paths.where((path) => path == '/api/auth/refresh'),
      hasLength(1),
    );
  });

  test('invalid refresh clears sessions and emits expiration', () async {
    await _saveExpiringSessions(local, now);
    final adapter = _RefreshAdapter(refreshStatus: 401);
    final coordinator = _coordinator(local, adapter, now);
    addTearDown(coordinator.dispose);
    final event = coordinator.changes.first;

    expect(await coordinator.forceRefreshAccessToken(), isNull);
    expect((await event).expired, isTrue);
    expect(await local.readAccountSession(), isNull);
    expect(await local.readSession(), isNull);
  });

  test('network failure keeps the stored session', () async {
    await _saveExpiringSessions(local, now);
    final adapter = _RefreshAdapter(networkFailure: true);
    final coordinator = _coordinator(local, adapter, now);
    addTearDown(coordinator.dispose);

    await expectLater(
      coordinator.forceRefreshAccessToken(),
      throwsA(isA<DioException>()),
    );
    expect(await local.readAccountSession(), isNotNull);
    expect(await local.readSession(), isNotNull);
  });
}

AuthSessionCoordinator _coordinator(
  AuthLocalDataSource local,
  HttpClientAdapter adapter,
  DateTime now,
) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return AuthSessionCoordinator(
    config: const AppConfig(apiBaseUrl: 'http://example.test'),
    localDataSource: local,
    authDio: dio,
    now: () => now,
  );
}

Future<void> _saveExpiringSessions(
  AuthLocalDataSource local,
  DateTime now,
) async {
  await local.saveAccountSession(
    AccountSessionModel(
      accessToken: 'old-account-token',
      expiresAt: now.add(const Duration(seconds: 30)),
      refreshToken: 'refresh-1',
      refreshTokenExpiresAt: now.add(const Duration(days: 30)),
      userId: 42,
      email: 'member@example.com',
      studios: const [],
    ),
  );
  await local.saveSession(
    AuthSessionModel(
      accessToken: 'old-studio-token',
      expiresAt: now.add(const Duration(seconds: 30)),
      user: const AuthenticatedUserModel(
        id: 42,
        studioId: 7,
        memberId: 11,
        trainerId: null,
        email: 'member@example.com',
        roles: ['member'],
      ),
    ),
  );
}

class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({
    this.refreshStatus = 200,
    this.networkFailure = false,
    this.delay,
  });

  final int refreshStatus;
  final bool networkFailure;
  final Duration? delay;
  final paths = <String>[];
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (delay != null) await Future<void>.delayed(delay!);
    if (networkFailure) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (options.path.endsWith('/select')) {
      authorization = options.headers['Authorization'] as String?;
      return _json(_studioJson, 200);
    }
    return _json(_accountJson, refreshStatus);
  }

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

const _accountJson = <String, dynamic>{
  'accessToken': 'new-account-token',
  'expiresAt': '2026-10-16T10:15:00Z',
  'refreshToken': 'refresh-2',
  'refreshTokenExpiresAt': '2026-11-15T10:00:00Z',
  'user': {'id': 42, 'email': 'member@example.com'},
  'studios': <Map<String, dynamic>>[],
};

const _studioJson = <String, dynamic>{
  'accessToken': 'new-studio-token',
  'expiresAt': '2026-10-16T10:15:00Z',
  'user': {
    'id': 42,
    'studioId': 7,
    'memberId': 11,
    'trainerId': null,
    'email': 'member@example.com',
    'roles': ['member'],
  },
};
