import 'package:dio/dio.dart';

import '../auth/access_token_provider.dart';
import '../config/app_config.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AccessTokenProvider accessTokenProvider,
    Dio? dio,
  }) : _dio =
           dio ??
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
           ) {
    _dio.interceptors.add(AuthInterceptor(accessTokenProvider));
  }

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _send(() => _dio.get<T>(path, queryParameters: queryParameters));
  }

  Future<Response<T>> post<T>(String path, {Object? data}) {
    return _send(() => _dio.post<T>(path, data: data));
  }

  Future<Response<T>> patch<T>(String path, {Object? data}) {
    return _send(() => _dio.patch<T>(path, data: data));
  }

  Future<Response<T>> delete<T>(String path) {
    return _send(() => _dio.delete<T>(path));
  }

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
