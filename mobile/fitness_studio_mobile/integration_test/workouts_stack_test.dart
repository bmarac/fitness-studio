import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/network/api_exception.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_session_workouts_page.dart';
import 'package:test/test.dart';

void main() {
  test(
    'staff reads trainer-scoped paged workouts while a member is forbidden',
    () async {
      final apiBaseUrl = _requiredEnvironmentValue(
        'FITNESS_STUDIO_TEST_API_BASE_URL',
      );
      final tokenProvider = _MutableAccessTokenProvider();
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: apiBaseUrl),
        accessTokenProvider: tokenProvider,
      );
      final auth = AuthRemoteDataSource(client);
      final getWorkouts = GetClassSessionWorkoutsPage(
        ClassSessionsRepositoryImpl(ClassSessionsRemoteDataSource(client)),
      );

      final filip = await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: 'filip.saric@stayfitjoyful.demo',
      );
      final filipTrainerId = filip.user.trainerId;
      expect(filipTrainerId, isNotNull);

      final firstPage = _expectSuccess(
        await getWorkouts(
          filter: 'active',
          page: 1,
          pageSize: 1,
          trainerId: filipTrainerId,
        ),
      );
      expect(firstPage.page, 1);
      expect(firstPage.pageSize, 1);
      expect(firstPage.items, hasLength(1));
      expect(firstPage.hasNextPage, isTrue);
      expect(firstPage.items.single.trainerId, filipTrainerId);

      final secondPage = _expectSuccess(
        await getWorkouts(
          filter: 'active',
          page: 2,
          pageSize: 1,
          trainerId: filipTrainerId,
        ),
      );
      expect(secondPage.page, 2);
      expect(secondPage.items, hasLength(1));
      expect(secondPage.items.single.trainerId, filipTrainerId);
      expect(secondPage.items.single.id, isNot(firstPage.items.single.id));
      expect(
        secondPage.items.single.startsAt.isBefore(
          firstPage.items.single.startsAt,
        ),
        isFalse,
      );

      final kristina = await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: 'kristina.lisec@stayfitjoyful.demo',
      );
      final kristinaTrainerId = kristina.user.trainerId;
      expect(kristinaTrainerId, isNotNull);
      expect(kristinaTrainerId, isNot(filipTrainerId));

      final kristinaPage = _expectSuccess(
        await getWorkouts(
          filter: 'active',
          page: 1,
          pageSize: 5,
          trainerId: kristinaTrainerId,
        ),
      );
      expect(kristinaPage.items, isNotEmpty);
      expect(kristinaPage.items.map((session) => session.trainerId).toSet(), {
        kristinaTrainerId,
      });

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: 'ana.horvat@stayfitjoyful.demo',
      );
      final forbidden = await getWorkouts(
        filter: 'active',
        page: 1,
        pageSize: 5,
      );
      _expectFailureStatus(forbidden, 403);
    },
  );
}

Future<AuthSession> _login(
  AuthRemoteDataSource auth,
  _MutableAccessTokenProvider tokenProvider, {
  required String apiBaseUrl,
  required String email,
}) async {
  try {
    final account = await auth.login(email: email, password: 'Fitness123!');
    tokenProvider.accessToken = account.accessToken;
    final studio = account.studios.singleWhere((item) => item.studioId == 1);
    final session = await auth.selectStudio(studio.studioId);
    tokenProvider.accessToken = session.accessToken;
    return session;
  } on ApiException catch (error) {
    throw TestFailure(
      'Could not log in as $email through $apiBaseUrl: ${error.message}',
    );
  }
}

T _expectSuccess<T>(Result<T> result) {
  return switch (result) {
    Success<T>(value: final value) => value,
    FailureResult<T>(failure: final failure) => throw TestFailure(
      'Expected a successful API result, but received: $failure',
    ),
  };
}

void _expectFailureStatus<T>(Result<T> result, int statusCode) {
  switch (result) {
    case Success():
      fail('Expected HTTP $statusCode, but the API call succeeded.');
    case FailureResult(failure: final failure):
      expect(failure.statusCode, statusCode);
  }
}

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh workouts-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
