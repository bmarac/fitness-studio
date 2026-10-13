import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:test/test.dart';

void main() {
  test(
    'new account joins and selects a studio through the live stack',
    () async {
      final apiBaseUrl = _requiredEnvironmentValue(
        'FITNESS_STUDIO_TEST_API_BASE_URL',
      );
      final tokenProvider = _MutableAccessTokenProvider();
      final auth = AuthRemoteDataSource(
        ApiClient(
          config: AppConfig(apiBaseUrl: apiBaseUrl),
          accessTokenProvider: tokenProvider,
        ),
      );

      const email = 'account.stack@example.test';
      const password = 'AccountStack123!';
      final registered = await auth.register(email: email, password: password);
      expect(registered.userId, greaterThan(0));
      expect(registered.email, email);
      expect(registered.studios, isEmpty);
      tokenProvider.accessToken = registered.accessToken;

      final lookup = await auth.lookupStudio('stayfit');
      expect(lookup.studioName, 'Stay Fit & Joyful');
      expect(lookup.requiresProfileDetails, isTrue);
      expect(lookup.role, 'member');

      final joined = await auth.joinStudio(
        code: 'STAYFIT',
        firstName: 'Account',
        lastName: 'Stack',
      );
      expect(joined.memberId, isNotNull);
      expect(joined.roles, ['member']);

      final repeated = await auth.joinStudio(code: 'STAYFIT');
      expect(repeated.studioId, joined.studioId);
      expect(repeated.memberId, joined.memberId);

      final persisted = await auth.login(email: email, password: password);
      expect(persisted.studios, hasLength(1));
      expect(persisted.studios.single.memberId, joined.memberId);
      tokenProvider.accessToken = persisted.accessToken;

      final session = await auth.selectStudio(joined.studioId);
      expect(session.accessToken, isNotEmpty);
      expect(session.user.email, email);
      expect(session.user.studioId, joined.studioId);
      expect(session.user.memberId, joined.memberId);
      expect(session.user.roles, contains('member'));
    },
  );
}

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh account-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
