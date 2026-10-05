class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.studioId,
    required this.memberId,
    required this.trainerId,
    required this.email,
    required this.roles,
  });

  final int id;
  final int studioId;
  final int? memberId;
  final int? trainerId;
  final String email;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);
}
