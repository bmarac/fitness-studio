import '../../../../core/auth/access_token_provider.dart';
import '../datasources/auth_local_data_source.dart';

class SecureAccessTokenProvider implements AccessTokenProvider {
  const SecureAccessTokenProvider(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  Future<String?> getAccessToken() async {
    final session = await _localDataSource.readSession();

    if (session == null) {
      return null;
    }

    if (!session.expiresAt.isAfter(DateTime.now().toUtc())) {
      await _localDataSource.clearSession();
      return null;
    }

    return session.accessToken;
  }
}
