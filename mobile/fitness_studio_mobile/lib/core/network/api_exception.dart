import 'package:dio/dio.dart';

import '../error/failure.dart';

enum ApiExceptionKind { remote, notFound, network }

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.kind = ApiExceptionKind.remote,
  });

  final String message;
  final int? statusCode;
  final ApiExceptionKind kind;

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      final title = data['title'];

      return ApiException(
        message: detail is String
            ? detail
            : title is String
            ? title
            : 'Request failed.',
        statusCode: response?.statusCode,
      );
    }

    if (response?.statusCode == 404) {
      return const ApiException(
        message: 'Not found.',
        statusCode: 404,
        kind: ApiExceptionKind.notFound,
      );
    }

    return ApiException(
      message: error.message ?? 'Network request failed.',
      statusCode: response?.statusCode,
      kind: ApiExceptionKind.network,
    );
  }
}

extension ApiExceptionFailure on ApiException {
  Failure toFailure() => switch (kind) {
    ApiExceptionKind.remote => Failure.remote(message, statusCode: statusCode),
    ApiExceptionKind.notFound => Failure(
      FailureKind.notFound,
      statusCode: statusCode,
    ),
    ApiExceptionKind.network => Failure(
      FailureKind.network,
      statusCode: statusCode,
    ),
  };
}
