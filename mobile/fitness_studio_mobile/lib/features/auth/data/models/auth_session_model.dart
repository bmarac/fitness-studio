import '../../domain/entities/auth_session.dart';
import 'authenticated_user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.expiresAt,
    required AuthenticatedUserModel super.user,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'accessToken': String accessToken,
        'expiresAt': String expiresAt,
        'user': Map<String, dynamic> user,
      } =>
        AuthSessionModel(
          accessToken: accessToken,
          expiresAt: DateTime.parse(expiresAt),
          user: AuthenticatedUserModel.fromJson(user),
        ),
      _ => throw const FormatException('Invalid login response.'),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': (user as AuthenticatedUserModel).toJson(),
    };
  }
}
