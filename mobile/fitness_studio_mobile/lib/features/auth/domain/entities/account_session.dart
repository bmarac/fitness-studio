import 'studio_membership.dart';

class AccountSession {
  const AccountSession({
    required this.accessToken,
    required this.expiresAt,
    required this.userId,
    required this.email,
    required this.studios,
  });

  final String accessToken;
  final DateTime expiresAt;
  final int userId;
  final String email;
  final List<StudioMembership> studios;
}
