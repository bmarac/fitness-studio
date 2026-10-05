import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:fitness_studio_mobile/features/auth/data/models/authenticated_user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthLocalDataSource dataSource;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    dataSource = const AuthLocalDataSource(FlutterSecureStorage());
  });

  test('saves, reads and clears auth session', () async {
    final session = AuthSessionModel(
      accessToken: 'token-value',
      expiresAt: DateTime.utc(2026, 9, 22, 14, 30),
      user: const AuthenticatedUserModel(
        id: 10,
        studioId: 1,
        memberId: 2,
        trainerId: null,
        email: 'ana.horvat@example.com',
        roles: ['member'],
      ),
    );

    await dataSource.saveSession(session);
    final restoredSession = await dataSource.readSession();

    expect(restoredSession?.accessToken, 'token-value');
    expect(restoredSession?.user.memberId, 2);

    await dataSource.clearSession();

    expect(await dataSource.readSession(), isNull);
  });
}
