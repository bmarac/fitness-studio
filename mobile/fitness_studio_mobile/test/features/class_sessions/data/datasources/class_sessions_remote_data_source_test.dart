import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends the selected week boundaries to the API', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final adapter = _CapturingAdapter();
    dio.httpClientAdapter = adapter;
    final dataSource = ClassSessionsRemoteDataSource(
      ApiClient(
        config: const AppConfig(apiBaseUrl: 'http://example.test'),
        accessTokenProvider: const _NoTokenProvider(),
        dio: dio,
      ),
    );
    final from = DateTime.parse('2026-10-13T12:00:00Z');
    final to = DateTime.parse('2026-10-19T00:00:00Z');

    await dataSource.getClassSessions(from: from, to: to);

    expect(adapter.request?.path, '/api/class-sessions');
    expect(adapter.request?.queryParameters, {
      'from': '2026-10-13T12:00:00.000Z',
      'to': '2026-10-19T00:00:00.000Z',
    });
  });
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      '[]',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
