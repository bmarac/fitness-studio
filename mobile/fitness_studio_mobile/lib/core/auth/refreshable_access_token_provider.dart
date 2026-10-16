import 'access_token_provider.dart';

abstract class RefreshableAccessTokenProvider implements AccessTokenProvider {
  Future<String?> forceRefreshAccessToken({String? rejectedAccessToken});
}
