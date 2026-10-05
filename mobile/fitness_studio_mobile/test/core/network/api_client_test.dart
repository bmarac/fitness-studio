import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds bearer token to outgoing requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final adapter = _CapturingAdapter();
    dio.httpClientAdapter = adapter;
    final client = ApiClient(
      config: const AppConfig(
        apiBaseUrl: 'http://example.test',
        currentStudioId: 1,
      ),
      accessTokenProvider: const _FakeAccessTokenProvider('token-value'),
      dio: dio,
    );

    await client.get<Map<String, dynamic>>('/api/test');

    expect(adapter.request?.headers['Authorization'], 'Bearer token-value');
  });
}

class _FakeAccessTokenProvider implements AccessTokenProvider {
  const _FakeAccessTokenProvider(this.token);

  final String? token;

  @override
  Future<String?> getAccessToken() async => token;
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
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
