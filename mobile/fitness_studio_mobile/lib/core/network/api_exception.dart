import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

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
        message: 'Trazeni podatak nije pronaden.',
        statusCode: 404,
      );
    }

    return ApiException(
      message: error.message ?? 'Network request failed.',
      statusCode: response?.statusCode,
    );
  }
}
