import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/trainers/data/trainers_management_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'lists and creates trainers through the standard trainers API',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
      final adapter = _TrainerApiAdapter();
      dio.httpClientAdapter = adapter;
      final dataSource = TrainersManagementRemoteDataSource(
        ApiClient(
          config: const AppConfig(apiBaseUrl: 'http://example.test'),
          accessTokenProvider: const _NoTokenProvider(),
          dio: dio,
        ),
      );

      final trainers = await dataSource.getTrainers();
      final created = await dataSource.createTrainer({
        'firstName': 'Filip',
        'lastName': 'Šarić',
        'email': 'filip@example.com',
      });

      expect(trainers.single['email'], 'filip@example.com');
      expect(created['id'], 7);
      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
      ]);
      expect(adapter.requests.map((request) => request.path), [
        '/api/trainers',
        '/api/trainers',
      ]);
    },
  );
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _TrainerApiAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final body = options.method == 'GET'
        ? [
            {
              'id': 7,
              'firstName': 'Filip',
              'lastName': 'Šarić',
              'email': 'filip@example.com',
            },
          ]
        : {
            'id': 7,
            'firstName': 'Filip',
            'lastName': 'Šarić',
            'email': 'filip@example.com',
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      options.method == 'GET' ? 200 : 201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
