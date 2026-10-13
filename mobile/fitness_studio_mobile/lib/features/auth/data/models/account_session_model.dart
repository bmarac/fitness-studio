import '../../domain/entities/account_session.dart';
import '../../domain/entities/studio_membership.dart';

class AccountSessionModel extends AccountSession {
  const AccountSessionModel({
    required super.accessToken,
    required super.expiresAt,
    required super.userId,
    required super.email,
    required super.studios,
  });

  factory AccountSessionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final studios = json['studios'];
    if (json['accessToken'] is! String ||
        json['expiresAt'] is! String ||
        user is! Map<String, dynamic> ||
        user['id'] is! int ||
        user['email'] is! String ||
        studios is! List<dynamic>) {
      throw const FormatException('Invalid account session response.');
    }
    return AccountSessionModel(
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userId: user['id'] as int,
      email: user['email'] as String,
      studios: studios
          .map(
            (item) =>
                StudioMembershipModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toIso8601String(),
    'user': {'id': userId, 'email': email},
    'studios': studios.map(StudioMembershipModel.toJson).toList(),
  };
}

class StudioMembershipModel extends StudioMembership {
  const StudioMembershipModel({
    required super.studioId,
    required super.studioName,
    required super.memberId,
    required super.trainerId,
    required super.roles,
  });

  factory StudioMembershipModel.fromJson(Map<String, dynamic> json) =>
      StudioMembershipModel(
        studioId: json['studioId'] as int,
        studioName: json['studioName'] as String,
        memberId: json['memberId'] as int?,
        trainerId: json['trainerId'] as int?,
        roles: List<String>.unmodifiable(
          (json['roles'] as List<dynamic>).cast<String>(),
        ),
      );

  static Map<String, dynamic> toJson(StudioMembership value) => {
    'studioId': value.studioId,
    'studioName': value.studioName,
    'memberId': value.memberId,
    'trainerId': value.trainerId,
    'roles': value.roles,
  };
}
