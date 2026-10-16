import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/cancel_class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_session_workouts_page.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_sessions.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_my_class_sessions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository and use cases forward every successful operation', () async {
    final adapter = _ClassSessionsAdapter();
    final repository = ClassSessionsRepositoryImpl(_source(adapter));
    final from = DateTime.utc(2030, 1, 1);
    final to = DateTime.utc(2030, 1, 8);

    final sessions = await GetClassSessions(repository)(from: from, to: to);
    final mine = await GetMyClassSessions(repository)();
    final workouts = await GetClassSessionWorkoutsPage(repository)(
      filter: 'completed',
      page: 2,
      pageSize: 10,
      trainerId: 7,
    );
    final detail = await GetClassSession(repository)(21);
    final cancellation = await CancelClassSession(repository)(21);

    expect((sessions as Success).value.single.id, 21);
    expect((mine as Success).value.single.classTypeName, 'Pilates');
    expect((workouts as Success).value.page, 2);
    expect((detail as Success).value.trainerFullName, 'Filip Šarić');
    expect(cancellation, isA<Success<void>>());
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/class-sessions',
        'GET /api/class-sessions/mine',
        'GET /api/class-sessions/workouts',
        'GET /api/class-sessions/21',
        'PATCH /api/class-sessions/21/cancel',
      ],
    );
    expect(adapter.requests.first.queryParameters, {
      'from': '2030-01-01T00:00:00.000Z',
      'to': '2030-01-08T00:00:00.000Z',
    });
    expect(adapter.requests[2].queryParameters, {
      'filter': 'completed',
      'page': 2,
      'pageSize': 10,
      'trainerId': 7,
    });
  });

  test('repository maps malformed responses to read API failures', () async {
    final repository = ClassSessionsRepositoryImpl(
      _source(_ClassSessionsAdapter(malformed: true)),
    );

    final results = <Result<Object?>>[
      await repository.getClassSessions(),
      await repository.getMyClassSessions(),
      await repository.getWorkoutClassSessions(
        filter: 'upcoming',
        page: 1,
        pageSize: 20,
      ),
      await repository.getClassSession(21),
    ];

    for (final result in results) {
      expect(result, isA<FailureResult>());
      expect((result as FailureResult).failure.kind, FailureKind.readApi);
    }
  });

  test('repository preserves API failures for every operation', () async {
    final repository = ClassSessionsRepositoryImpl(
      _source(_ClassSessionsAdapter(statusCode: 409)),
    );

    final results = <Result<Object?>>[
      await repository.getClassSessions(),
      await repository.getMyClassSessions(),
      await repository.getWorkoutClassSessions(
        filter: 'upcoming',
        page: 1,
        pageSize: 20,
      ),
      await repository.getClassSession(21),
      await repository.cancelClassSession(21),
    ];

    for (final result in results) {
      expect(result, isA<FailureResult>());
      expect((result as FailureResult).failure.statusCode, 409);
    }
  });
}

ClassSessionsRemoteDataSource _source(_ClassSessionsAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ClassSessionsRemoteDataSource(
    ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://example.test'),
      accessTokenProvider: const _NoTokenProvider(),
      dio: dio,
    ),
  );
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _ClassSessionsAdapter implements HttpClientAdapter {
  _ClassSessionsAdapter({this.malformed = false, this.statusCode = 200});

  final bool malformed;
  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object? body = malformed
        ? switch (options.path) {
            '/api/class-sessions' || '/api/class-sessions/mine' => [null],
            '/api/class-sessions/workouts' => {
              'items': [null],
              'page': 1,
              'pageSize': 20,
              'hasNextPage': false,
            },
            '/api/class-sessions/21' => const <String, dynamic>{},
            _ => null,
          }
        : switch (options.path) {
            '/api/class-sessions' ||
            '/api/class-sessions/mine' => [_sessionJson],
            '/api/class-sessions/workouts' => {
              'items': [_sessionJson],
              'page': 2,
              'pageSize': 10,
              'hasNextPage': false,
            },
            '/api/class-sessions/21' => _sessionJson,
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

const _sessionJson = <String, dynamic>{
  'id': 21,
  'classTypeId': 5,
  'classTypeName': 'Pilates',
  'trainerId': 7,
  'trainerFirstName': 'Filip',
  'trainerLastName': 'Šarić',
  'startsAt': '2030-01-03T17:00:00Z',
  'endsAt': '2030-01-03T18:00:00Z',
  'capacity': 12,
  'bookedCount': 4,
  'status': 'scheduled',
  'recurringScheduleId': null,
  'recurringScheduleStatus': null,
};
