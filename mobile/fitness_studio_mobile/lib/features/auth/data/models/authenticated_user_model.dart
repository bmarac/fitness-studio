import '../../domain/entities/authenticated_user.dart';

class AuthenticatedUserModel extends AuthenticatedUser {
  const AuthenticatedUserModel({
    required super.id,
    required super.studioId,
    required super.memberId,
    required super.trainerId,
    required super.email,
    required super.roles,
  });

  factory AuthenticatedUserModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'studioId': int studioId,
        'memberId': final int? memberId,
        'trainerId': final int? trainerId,
        'email': String email,
        'roles': List<dynamic> roles,
      } =>
        AuthenticatedUserModel(
          id: id,
          studioId: studioId,
          memberId: memberId,
          trainerId: trainerId,
          email: email,
          roles: _parseRoles(roles),
        ),
      _ => throw const FormatException('Invalid authenticated user response.'),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studioId': studioId,
      'memberId': memberId,
      'trainerId': trainerId,
      'email': email,
      'roles': roles,
    };
  }

  static List<String> _parseRoles(List<dynamic> values) {
    if (values.any((value) => value is! String)) {
      throw const FormatException('Invalid authenticated user roles.');
    }

    return List.unmodifiable(values.cast<String>());
  }
}
