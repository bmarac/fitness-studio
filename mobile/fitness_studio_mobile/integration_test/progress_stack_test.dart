import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/network/api_exception.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/progress/data/datasources/progress_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/progress_management.dart';
import 'package:test/test.dart';

void main() {
  test(
    'trainer records progress that the member reads with calculated BMI',
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
      final progress = ProgressRemoteDataSource(client);

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl,
        'filip.saric@stayfitjoyful.demo',
      );
      final ana = (await progress.getMembers()).singleWhere(
        (member) => member.email == 'ana.horvat@stayfitjoyful.demo',
      );
      final parameters = await progress.getMeasurementParameters();
      final height = parameters.singleWhere((item) => item.code == 'height_cm');
      final weight = parameters.singleWhere((item) => item.code == 'weight_kg');
      const note = 'Vertical progress verification';
      final measuredAt = DateTime.now().toUtc().subtract(
        const Duration(seconds: 1),
      );
      await progress.createMeasurement(
        ana.id,
        NewMeasurement(
          measuredAt: measuredAt,
          note: note,
          values: [
            NewMeasurementValue(parameterId: height.id, value: 172.5),
            NewMeasurementValue(parameterId: weight.id, value: 68.2),
          ],
        ),
      );

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl,
        'ana.horvat@stayfitjoyful.demo',
      );
      final loaded = await progress.getMemberProgress(ana.id);
      expect(loaded.latestByCode('height_cm')?.value, 172.5);
      expect(loaded.latestByCode('weight_kg')?.value, 68.2);
      final bmi = loaded.latestByCode('bmi');
      expect(bmi, isNotNull);
      expect(bmi!.value, closeTo(68.2 / (1.725 * 1.725), 0.1));
      final persisted = loaded.history.singleWhere((item) => item.note == note);
      expect(
        persisted.values.map((value) => value.code),
        containsAll(['height_cm', 'weight_kg', 'bmi']),
      );
    },
  );
}

Future<void> _login(
  AuthRemoteDataSource auth,
  _MutableAccessTokenProvider tokenProvider,
  String apiBaseUrl,
  String email,
) async {
  try {
    final account = await auth.login(email: email, password: 'Fitness123!');
    tokenProvider.accessToken = account.accessToken;
    final studio = account.studios.singleWhere((item) => item.studioId == 1);
    final session = await auth.selectStudio(studio.studioId);
    tokenProvider.accessToken = session.accessToken;
  } on ApiException catch (error) {
    throw TestFailure(
      'Could not log in as $email through $apiBaseUrl: ${error.message}',
    );
  }
}

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh progress-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;
  @override
  Future<String?> getAccessToken() async => accessToken;
}
