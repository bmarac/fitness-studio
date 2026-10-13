import '../../../../core/auth/access_token_provider.dart';
import '../datasources/auth_local_data_source.dart';

class SecureAccessTokenProvider implements AccessTokenProvider {
  const SecureAccessTokenProvider(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  Future<String?> getAccessToken() async {
    final studioSession = await _localDataSource.readSession();
    final accountSession = studioSession == null
        ? await _localDataSource.readAccountSession()
        : null;
    final accessToken =
        studioSession?.accessToken ?? accountSession?.accessToken;
    final expiresAt = studioSession?.expiresAt ?? accountSession?.expiresAt;
    if (accessToken == null || expiresAt == null) return null;
    if (!expiresAt.isAfter(DateTime.now().toUtc())) {
      await _localDataSource.clearSession();
      return null;
    }
    return accessToken;
  }
}
