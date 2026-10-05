import 'package:dio/dio.dart';

import '../auth/access_token_provider.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._accessTokenProvider);

  final AccessTokenProvider _accessTokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _accessTokenProvider.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }
}
