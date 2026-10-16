import 'studio_membership.dart';

class AccountSession {
  const AccountSession({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
    required this.userId,
    required this.email,
    required this.studios,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;
  final int userId;
  final String email;
  final List<StudioMembership> studios;
}
