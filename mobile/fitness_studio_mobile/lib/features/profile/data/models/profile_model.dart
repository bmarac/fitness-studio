import '../../domain/entities/profile.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.user,
    required super.studio,
    required super.member,
    required super.trainer,
    required super.membership,
    required super.usage,
    required super.fixedSchedules,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      user: _user(json['user'] as Map<String, dynamic>),
      studio: _studio(json['studio'] as Map<String, dynamic>),
      member: _person(json['member']),
      trainer: _person(json['trainer']),
      membership: _membership(json['membership']),
      usage: _usage(json['usage']),
      fixedSchedules: (json['fixedSchedules'] as List<dynamic>)
          .map((item) => _fixedSchedule(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static ProfileUser _user(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] as int,
      email: json['email'] as String,
      roles: (json['roles'] as List<dynamic>).cast<String>(),
    );
  }

  static ProfileStudio _studio(Map<String, dynamic> json) {
    return ProfileStudio(id: json['id'] as int, name: json['name'] as String);
  }

  static ProfilePerson? _person(dynamic value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return ProfilePerson(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      dateOfBirth: _optionalDate(json['dateOfBirth']),
      bio: json['bio'] as String?,
    );
  }

  static ProfileMembership? _membership(dynamic value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return ProfileMembership(
      id: json['id'] as int,
      planName: json['planName'] as String,
      planDescription: json['planDescription'] as String?,
      startsOn: DateTime.parse(json['startsOn'] as String),
      endsOn: DateTime.parse(json['endsOn'] as String),
      status: json['status'] as String,
      sessionLimit: json['sessionLimit'] as int?,
      sessionLimitPeriod: json['sessionLimitPeriod'] as String?,
    );
  }

  static ProfileUsage? _usage(dynamic value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    return ProfileUsage(
      periodStartsOn: DateTime.parse(json['periodStartsOn'] as String),
      periodEndsOn: DateTime.parse(json['periodEndsOn'] as String),
      used: json['used'] as int,
      allowed: json['allowed'] as int,
      period: json['period'] as String,
    );
  }

  static ProfileFixedSchedule _fixedSchedule(Map<String, dynamic> json) {
    return ProfileFixedSchedule(
      id: json['id'] as int,
      classTypeName: json['classTypeName'] as String,
      trainerName: json['trainerName'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startsAtTime: json['startsAtTime'] as String,
    );
  }

  static DateTime? _optionalDate(dynamic value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
