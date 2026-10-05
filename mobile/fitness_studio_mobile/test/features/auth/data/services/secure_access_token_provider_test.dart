import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/authenticated_user_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/services/secure_access_token_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthLocalDataSource dataSource;
  late SecureAccessTokenProvider tokenProvider;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dataSource = const AuthLocalDataSource(FlutterSecureStorage());
    tokenProvider = SecureAccessTokenProvider(dataSource);
  });

  test('returns token from a valid stored session', () async {
    await dataSource.saveSession(
      _session(DateTime.now().toUtc().add(const Duration(hours: 1))),
    );

    expect(await tokenProvider.getAccessToken(), 'token-value');
  });

  test('clears an expired session and returns no token', () async {
    await dataSource.saveSession(
      _session(DateTime.now().toUtc().subtract(const Duration(minutes: 1))),
    );

    expect(await tokenProvider.getAccessToken(), isNull);
    expect(await dataSource.readSession(), isNull);
  });
}

AuthSessionModel _session(DateTime expiresAt) {
  return AuthSessionModel(
    accessToken: 'token-value',
    expiresAt: expiresAt,
    user: const AuthenticatedUserModel(
      id: 10,
      studioId: 1,
      memberId: 2,
      trainerId: null,
      email: 'ana.horvat@example.com',
      roles: ['member'],
    ),
  );
}
