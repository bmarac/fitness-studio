import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/network/api_exception.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/datasources/recurring_schedules_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/repositories/recurring_schedules_repository_impl.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/change_recurring_schedule_status.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import 'package:test/test.dart';

void main() {
  test('schedule lifecycle is persisted and restricted to staff', () async {
    final apiBaseUrl = _requiredEnvironmentValue(
      'FITNESS_STUDIO_TEST_API_BASE_URL',
    );
    final tokenProvider = _MutableAccessTokenProvider();
    final client = ApiClient(
      config: AppConfig(apiBaseUrl: apiBaseUrl),
      accessTokenProvider: tokenProvider,
    );
    final auth = AuthRemoteDataSource(client);
    final repository = RecurringSchedulesRepositoryImpl(
      RecurringSchedulesRemoteDataSource(client),
    );
    final getSchedules = GetRecurringSchedules(repository);
    final changeStatus = ChangeRecurringScheduleStatus(repository);
    final effectiveFrom = _today();

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'ana.horvat@stayfitjoyful.demo',
    );
    final schedules = _expectSuccess(await getSchedules());
    final schedule = schedules.firstWhere((item) => item.status == 'active');
    _expectFailureStatus(
      await changeStatus(
        id: schedule.id,
        action: 'pause',
        effectiveFrom: effectiveFrom,
      ),
      403,
    );

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'filip.saric@stayfitjoyful.demo',
    );
    _expectSuccess(
      await changeStatus(
        id: schedule.id,
        action: 'pause',
        effectiveFrom: effectiveFrom,
      ),
    );

    final paused = _expectSuccess(
      await getSchedules(),
    ).singleWhere((item) => item.id == schedule.id);
    expect(paused.status, 'paused');
    expect(_dateOnly(paused.statusEffectiveFrom!), effectiveFrom);

    _expectSuccess(
      await changeStatus(
        id: schedule.id,
        action: 'resume',
        effectiveFrom: effectiveFrom,
      ),
    );

    final resumed = _expectSuccess(
      await getSchedules(),
    ).singleWhere((item) => item.id == schedule.id);
    expect(resumed.status, 'active');
    expect(resumed.statusEffectiveFrom, isNull);
  });
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

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh schedule-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
