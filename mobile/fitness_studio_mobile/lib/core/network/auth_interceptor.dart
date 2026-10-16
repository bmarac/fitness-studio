import 'package:dio/dio.dart';

import '../auth/access_token_provider.dart';
import '../auth/refreshable_access_token_provider.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._accessTokenProvider, this._dio);

  final AccessTokenProvider _accessTokenProvider;
  final Dio _dio;
  static const _retriedKey = 'auth-refresh-retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      handler.next(options);
      return;
    }
    final accessToken = await _accessTokenProvider.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final refreshable = _accessTokenProvider;
    if (err.response?.statusCode != 401 ||
        refreshable is! RefreshableAccessTokenProvider ||
        request.extra[_retriedKey] == true ||
        _isAuthEndpoint(request.path)) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await refreshable.forceRefreshAccessToken(
        rejectedAccessToken: _bearerToken(request),
      );
      if (accessToken == null) {
        handler.next(err);
        return;
      }
      request
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer $accessToken';
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isAuthEndpoint(String path) =>
      path == '/api/auth/login' ||
      path == '/api/auth/register' ||
      path == '/api/auth/refresh' ||
      path == '/api/auth/logout';

  String? _bearerToken(RequestOptions request) {
    final authorization = request.headers['Authorization'];
    return authorization is String && authorization.startsWith('Bearer ')
        ? authorization.substring(7)
        : null;
  }
}
