import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/studio_settings/data/configuration_items_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/studio_settings/data/studio_configuration_repository_impl.dart';
import 'package:fitness_studio_mobile/features/studio_settings/domain/configuration_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and atomically saves class type configuration', () async {
    final adapter = _ConfigurationAdapter();
    final repository = StudioConfigurationRepositoryImpl(_source(adapter));

    final classTypes = await repository.getClassTypes();
    await repository.saveClassTypes(
      const [
        ClassTypeConfiguration(
          id: 1,
          name: 'Pilates plus',
          defaultDurationMinutes: 75,
          defaultCapacity: 12,
          difficultyLevel: 'advanced',
          status: 'inactive',
        ),
      ],
      const [2],
    );
    expect(
      (classTypes as Success<List<ClassTypeConfiguration>>).value.single.name,
      'Pilates',
    );
    final classSave = adapter.requests.singleWhere(
      (request) => request.path == '/api/class-types/configuration',
    );
    expect(classSave.method, 'PUT');
    expect(classSave.data['deletedIds'], [2]);
    expect(classSave.data['items'][0]['name'], 'Pilates plus');
  });
}

ConfigurationItemsRemoteDataSource _source(_ConfigurationAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ConfigurationItemsRemoteDataSource(
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

class _ConfigurationAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    const Object body = [_classType];
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static const _classType = {
    'id': 1,
    'name': 'Pilates',
    'description': null,
    'defaultDurationMinutes': 60,
    'defaultCapacity': 10,
    'difficultyLevel': 'all_levels',
    'status': 'active',
  };
}
