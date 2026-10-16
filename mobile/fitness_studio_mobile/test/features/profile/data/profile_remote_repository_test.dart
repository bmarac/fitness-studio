import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fitness_studio_mobile/features/profile/domain/usecases/get_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'data source, repository, and use case load the profile route',
    () async {
      final adapter = _ProfileAdapter();
      final repository = ProfileRepositoryImpl(_source(adapter));

      final result = await GetProfile(repository)();

      final profile = (result as Success).value;
      expect(profile.user.email, 'ana@example.com');
      expect(profile.studio.name, 'Stay Fit');
      expect(profile.member!.fullName, 'Ana Horvat');
      expect(profile.membership!.planName, 'Monthly');
      expect(profile.usage!.allowed - profile.usage!.used, 5);
      expect(profile.fixedSchedules.single.classTypeName, 'Pilates');
      expect(adapter.request!.method, 'GET');
      expect(adapter.request!.path, '/api/profile');
    },
  );

  test('empty and malformed payloads become read API failures', () async {
    final empty = ProfileRepositoryImpl(_source(_ProfileAdapter(body: null)));
    final malformed = ProfileRepositoryImpl(
      _source(_ProfileAdapter(body: const <String, dynamic>{})),
    );

    final emptyResult = await empty.getProfile();
    final malformedResult = await malformed.getProfile();

    expect((emptyResult as FailureResult).failure.kind, FailureKind.readApi);
    expect(
      (malformedResult as FailureResult).failure.kind,
      FailureKind.readApi,
    );
  });

  test('repository preserves API status failures', () async {
    final repository = ProfileRepositoryImpl(
      _source(_ProfileAdapter(statusCode: 403)),
    );

    final result = await repository.getProfile();

    expect(result, isA<FailureResult>());
    expect((result as FailureResult).failure.statusCode, 403);
  });
}

ProfileRemoteDataSource _source(_ProfileAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return ProfileRemoteDataSource(
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

class _ProfileAdapter implements HttpClientAdapter {
  _ProfileAdapter({this.body = _profileJson, this.statusCode = 200});

  final Object? body;
  final int statusCode;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _profileJson = <String, dynamic>{
  'user': {
    'id': 1,
    'email': 'ana@example.com',
    'roles': ['member'],
  },
  'studio': {'id': 1, 'name': 'Stay Fit'},
  'member': {
    'id': 11,
    'firstName': 'Ana',
    'lastName': 'Horvat',
    'email': 'ana@example.com',
    'phone': null,
    'status': 'active',
    'dateOfBirth': '1992-04-12',
    'bio': null,
  },
  'trainer': null,
  'membership': {
    'id': 31,
    'planName': 'Monthly',
    'planDescription': 'Monthly membership',
    'startsOn': '2030-01-01',
    'endsOn': '2030-01-31',
    'isActive': true,
    'sessionLimit': 8,
    'sessionLimitPeriod': 'month',
  },
  'usage': {
    'periodStartsOn': '2030-01-01',
    'periodEndsOn': '2030-01-31',
    'used': 3,
    'allowed': 8,
    'period': 'month',
  },
  'fixedSchedules': [
    {
      'id': 41,
      'classTypeName': 'Pilates',
      'trainerName': 'Filip Šarić',
      'dayOfWeek': 1,
      'startsAtTime': '18:00:00',
    },
  ],
};
