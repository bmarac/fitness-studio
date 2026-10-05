import 'authenticated_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAt;
  final AuthenticatedUser user;
}
