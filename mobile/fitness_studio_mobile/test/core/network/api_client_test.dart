import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/auth/refreshable_access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds bearer token to outgoing requests', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final adapter = _CapturingAdapter();
    dio.httpClientAdapter = adapter;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://example.test'),
      accessTokenProvider: const _FakeAccessTokenProvider('token-value'),
      dio: dio,
    );

    await client.get<Map<String, dynamic>>('/api/test');

    expect(adapter.request?.headers['Authorization'], 'Bearer token-value');
  });

  test('refreshes once and retries a 401 request', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final adapter = _RetryAdapter();
    final provider = _RefreshingTokenProvider();
    dio.httpClientAdapter = adapter;
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://example.test'),
      accessTokenProvider: provider,
      dio: dio,
    );

    final response = await client.get<Map<String, dynamic>>('/api/test');

    expect(response.statusCode, 200);
    expect(adapter.authorization, ['Bearer old-token', 'Bearer new-token']);
    expect(provider.refreshCalls, 1);
  });
}

class _RefreshingTokenProvider implements RefreshableAccessTokenProvider {
  int refreshCalls = 0;

  @override
  Future<String?> getAccessToken() async =>
      refreshCalls == 0 ? 'old-token' : 'new-token';

  @override
  Future<String?> forceRefreshAccessToken({String? rejectedAccessToken}) async {
    refreshCalls++;
    return 'new-token';
  }
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

class _RetryAdapter implements HttpClientAdapter {
  final authorization = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    authorization.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString(
      '{}',
      authorization.length == 1 ? 401 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
