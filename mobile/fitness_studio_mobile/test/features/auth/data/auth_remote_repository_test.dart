import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/notifications/push_notifications_service.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthRemoteDataSource', () {
    test('uses exact account and studio routes and payloads', () async {
      final adapter = _AuthApiAdapter();
      final source = AuthRemoteDataSource(_client(adapter));

      final login = await source.login(
        email: 'member@example.com',
        password: 'Password123!',
      );
      await source.register(email: 'new@example.com', password: 'Password123!');
      final selected = await source.selectStudio(7);
      final lookup = await source.lookupStudio('STAYFIT');
      final joined = await source.joinStudio(
        code: 'STAYFIT',
        firstName: 'Ana',
        lastName: 'Horvat',
      );

      expect(login.userId, 42);
      expect(selected.user.studioId, 7);
      expect(lookup.requiresProfileDetails, isTrue);
      expect(joined.memberId, 11);
      expect(adapter.requests.map((request) => request.path), [
        '/api/auth/login',
        '/api/auth/register',
        '/api/account/studios/7/select',
        '/api/account/studios/lookup',
        '/api/account/studios/join',
      ]);
      expect(adapter.requests[0].data, {
        'email': 'member@example.com',
        'password': 'Password123!',
      });
      expect(adapter.requests[3].data, {'code': 'STAYFIT'});
      expect(adapter.requests[4].data, {
        'code': 'STAYFIT',
        'firstName': 'Ana',
        'lastName': 'Horvat',
      });
    });

    test('rejects empty responses for every response shape', () async {
      final source = AuthRemoteDataSource(
        _client(_AuthApiAdapter(returnNull: true)),
      );

      await expectLater(
        source.login(email: 'a@b.test', password: 'Password123!'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        source.selectStudio(7),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        source.lookupStudio('STAYFIT'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        source.joinStudio(code: 'STAYFIT'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AuthRepositoryImpl', () {
    late AuthLocalDataSource local;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      local = const AuthLocalDataSource(FlutterSecureStorage());
    });

    test(
      'normalizes account input, saves sessions and registers push token',
      () async {
        final adapter = _AuthApiAdapter();
        final push = _RecordingPushService(_client(_AuthApiAdapter()));
        final repository = AuthRepositoryImpl(
          AuthRemoteDataSource(_client(adapter)),
          local,
          push,
        );

        final login = await repository.login(
          email: ' MEMBER@Example.COM ',
          password: 'Password123!',
        );
        final selected = await repository.selectStudio(7);

        expect(login, isA<Success>());
        expect(selected, isA<Success>());
        expect(adapter.requests[0].data['email'], 'member@example.com');
        expect((await local.readAccountSession())?.userId, 42);
        expect((await local.readSession())?.user.studioId, 7);
        expect(await local.readLastStudioId(), 7);
        expect(push.registerCalls, 2);
      },
    );

    test(
      'normalizes lookup and join and adds joined studio to cached account',
      () async {
        final adapter = _AuthApiAdapter();
        final repository = AuthRepositoryImpl(
          AuthRemoteDataSource(_client(adapter)),
          local,
        );
        await repository.login(
          email: 'member@example.com',
          password: 'Password123!',
        );

        final lookup = await repository.lookupStudio(' stayfit ');
        final joined = await repository.joinStudio(
          code: ' stayfit ',
          firstName: ' Ana ',
          lastName: ' Horvat ',
        );

        expect(lookup, isA<Success>());
        expect(joined, isA<Success>());
        expect(adapter.requests[1].data, {'code': 'STAYFIT'});
        expect(adapter.requests[2].data, {
          'code': 'STAYFIT',
          'firstName': 'Ana',
          'lastName': 'Horvat',
        });
        expect((await local.readAccountSession())?.studios.single.studioId, 7);
      },
    );

    test('maps malformed and API responses to stable failures', () async {
      final malformed = AuthRepositoryImpl(
        AuthRemoteDataSource(_client(_AuthApiAdapter(returnNull: true))),
        local,
      );
      final remote = AuthRepositoryImpl(
        AuthRemoteDataSource(_client(_AuthApiAdapter(statusCode: 409))),
        local,
      );

      for (final result in [
        await malformed.login(email: 'a@b.test', password: 'Password123!'),
        await malformed.selectStudio(7),
        await malformed.lookupStudio('STAYFIT'),
        await malformed.joinStudio(code: 'STAYFIT'),
      ]) {
        expect(
          (result as FailureResult).failure.kind,
          FailureKind.loginResponse,
        );
      }
      for (final result in [
        await remote.register(email: 'a@b.test', password: 'Password123!'),
        await remote.selectStudio(7),
        await remote.lookupStudio('STAYFIT'),
        await remote.joinStudio(code: 'STAYFIT'),
      ]) {
        final failure = (result as FailureResult).failure;
        expect(failure.kind, FailureKind.remote);
        expect(failure.statusCode, 409);
      }
    });

    test('logout unregisters push and clears both saved sessions', () async {
      final push = _RecordingPushService(_client(_AuthApiAdapter()));
      final repository = AuthRepositoryImpl(
        AuthRemoteDataSource(_client(_AuthApiAdapter())),
        local,
        push,
      );
      await repository.login(
        email: 'member@example.com',
        password: 'Password123!',
      );

      final result = await repository.logout();

      expect(result, isA<Success<void>>());
      expect(push.unregisterCalls, 1);
      expect(await local.readAccountSession(), isNull);
      expect(await local.readSession(), isNull);
    });
  });
}

ApiClient _client(_AuthApiAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ApiClient(
    config: const AppConfig(apiBaseUrl: 'http://example.test'),
    accessTokenProvider: const _NoTokenProvider(),
    dio: dio,
  );
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _RecordingPushService extends PushNotificationsService {
  _RecordingPushService(super.api);

  int registerCalls = 0;
  int unregisterCalls = 0;

  @override
  Future<void> registerCurrentToken() async => registerCalls++;

  @override
  Future<void> unregisterCurrentToken() async => unregisterCalls++;
}

class _AuthApiAdapter implements HttpClientAdapter {
  _AuthApiAdapter({this.returnNull = false, this.statusCode = 200});

  final bool returnNull;
  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = returnNull
        ? null
        : switch (options.path) {
            '/api/auth/login' || '/api/auth/register' => _accountJson,
            '/api/account/studios/7/select' => _sessionJson,
            '/api/account/studios/lookup' => _lookupJson,
            '/api/account/studios/join' => _studioJson,
            _ => const <String, dynamic>{},
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _studioJson = <String, dynamic>{
  'studioId': 7,
  'studioName': 'Stay Fit',
  'memberId': 11,
  'trainerId': null,
  'roles': ['member'],
};

const _accountJson = <String, dynamic>{
  'accessToken': 'account-token',
  'expiresAt': '2030-01-01T12:00:00Z',
  'user': {'id': 42, 'email': 'member@example.com'},
  'studios': <Map<String, dynamic>>[],
};

const _sessionJson = <String, dynamic>{
  'accessToken': 'studio-token',
  'expiresAt': '2030-01-01T12:00:00Z',
  'user': {
    'id': 42,
    'studioId': 7,
    'memberId': 11,
    'trainerId': null,
    'email': 'member@example.com',
    'roles': ['member'],
  },
};

const _lookupJson = <String, dynamic>{
  'studioId': 7,
  'studioName': 'Stay Fit',
  'requiresProfileDetails': true,
  'role': 'member',
};
