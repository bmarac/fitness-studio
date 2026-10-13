import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/progress/data/datasources/progress_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/progress_management.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads latest and history in parallel and parses management data',
    () async {
      final adapter = _ProgressAdapter();
      final source = _source(adapter);

      final progress = await source.getMemberProgress(7);
      final members = await source.getMembers();
      final parameters = await source.getMeasurementParameters();

      expect(progress.latestByCode('weight_kg')!.value, 68.4);
      expect(progress.history.single.note, 'Kontrola');
      expect(members.single.fullName, 'Ana Horvat');
      expect(parameters.first.code, 'height_cm');
      expect(parameters.last.canEnter, isFalse);
      expect(
        adapter.requests.map((request) => request.path),
        containsAll([
          '/api/members/7/measurements/latest',
          '/api/members/7/measurements',
          '/api/members',
          '/api/measurement-parameters',
        ]),
      );
    },
  );

  test('sends measurement to exact member route with UTC payload', () async {
    final adapter = _ProgressAdapter();
    final source = _source(adapter);

    await source.createMeasurement(
      7,
      NewMeasurement(
        measuredAt: DateTime.parse('2026-10-13T12:30:00+02:00'),
        note: 'Kontrola',
        values: const [NewMeasurementValue(parameterId: 2, value: 68.4)],
      ),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/members/7/measurements');
    expect(request.data, {
      'measuredAt': '2026-10-13T10:30:00.000Z',
      'note': 'Kontrola',
      'values': [
        {'parameterId': 2, 'value': 68.4},
      ],
    });
  });

  test('repository maps success and malformed responses', () async {
    final successful = ProgressRepositoryImpl(_source(_ProgressAdapter()));
    final malformed = ProgressRepositoryImpl(
      _source(_ProgressAdapter(malformedMembers: true)),
    );

    expect(await successful.getMemberProgress(7), isA<Success>());
    expect(await successful.getMembers(), isA<Success>());
    final result = await malformed.getMembers();

    expect(result, isA<FailureResult>());
    expect((result as FailureResult).failure.kind, FailureKind.readMembers);
  });

  test('repository preserves API failures for save operations', () async {
    final repository = ProgressRepositoryImpl(
      _source(_ProgressAdapter(saveStatus: 409)),
    );

    final result = await repository.createMeasurement(
      7,
      NewMeasurement(
        measuredAt: DateTime.now(),
        values: const [NewMeasurementValue(parameterId: 2, value: 68.4)],
      ),
    );

    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure.statusCode, 409);
  });
}

ProgressRemoteDataSource _source(_ProgressAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ProgressRemoteDataSource(
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

class _ProgressAdapter implements HttpClientAdapter {
  _ProgressAdapter({this.malformedMembers = false, this.saveStatus = 201});

  final bool malformedMembers;
  final int saveStatus;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object? body = switch ((options.method, options.path)) {
      ('GET', '/api/members/7/measurements/latest') => {
        'memberId': 7,
        'values': [_value(latest: true)],
      },
      ('GET', '/api/members/7/measurements') => [
        {
          'id': 1,
          'memberId': 7,
          'measuredAt': '2026-10-13T10:30:00Z',
          'note': 'Kontrola',
          'values': [_value()],
        },
      ],
      ('GET', '/api/members') =>
        malformedMembers
            ? null
            : [
                {
                  'id': 7,
                  'firstName': 'Ana',
                  'lastName': 'Horvat',
                  'email': 'ana@example.com',
                  'status': 'active',
                },
              ],
      ('GET', '/api/measurement-parameters') => [
        _parameter(1, 'height_cm', 'manual', 'active'),
        _parameter(3, 'bmi', 'calculated', 'active'),
      ],
      _ => <String, dynamic>{},
    };
    final status = options.method == 'POST' ? saveStatus : 200;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static Map<String, dynamic> _value({bool latest = false}) => {
    'parameterId': 2,
    'code': 'weight_kg',
    'name': 'Težina',
    'unit': 'kg',
    'value': 68.4,
    'decimalPlaces': 1,
    'sortOrder': 2,
    'source': 'manual',
    if (latest) 'measuredAt': '2026-10-13T10:30:00Z',
  };

  static Map<String, dynamic> _parameter(
    int id,
    String code,
    String source,
    String status,
  ) => {
    'id': id,
    'code': code,
    'name': code,
    'unit': null,
    'source': source,
    'minValue': null,
    'maxValue': null,
    'decimalPlaces': 1,
    'sortOrder': id,
    'status': status,
  };

  @override
  void close({bool force = false}) {}
}
