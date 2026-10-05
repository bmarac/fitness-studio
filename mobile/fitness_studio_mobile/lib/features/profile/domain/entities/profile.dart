class Profile {
  const Profile({
    required this.user,
    required this.studio,
    required this.member,
    required this.trainer,
    required this.membership,
    required this.usage,
    required this.fixedSchedules,
  });

  final ProfileUser user;
  final ProfileStudio studio;
  final ProfilePerson? member;
  final ProfilePerson? trainer;
  final ProfileMembership? membership;
  final ProfileUsage? usage;
  final List<ProfileFixedSchedule> fixedSchedules;

  ProfilePerson? get primaryPerson => member ?? trainer;
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.email,
    required this.roles,
  });

  final int id;
  final String email;
  final List<String> roles;
}

class ProfileStudio {
  const ProfileStudio({required this.id, required this.name});

  final int id;
  final String name;
}

class ProfilePerson {
  const ProfilePerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
    this.dateOfBirth,
    this.bio,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String status;
  final DateTime? dateOfBirth;
  final String? bio;

  String get fullName => '$firstName $lastName';
}

class ProfileMembership {
  const ProfileMembership({
    required this.id,
    required this.planName,
    required this.planDescription,
    required this.startsOn,
    required this.endsOn,
    required this.status,
    required this.sessionLimit,
    required this.sessionLimitPeriod,
  });

  final int id;
  final String planName;
  final String? planDescription;
  final DateTime startsOn;
  final DateTime endsOn;
  final String status;
  final int? sessionLimit;
  final String? sessionLimitPeriod;
}

class ProfileUsage {
  const ProfileUsage({
    required this.periodStartsOn,
    required this.periodEndsOn,
    required this.used,
    required this.allowed,
    required this.period,
  });

  final DateTime periodStartsOn;
  final DateTime periodEndsOn;
  final int used;
  final int allowed;
  final String period;
}

class ProfileFixedSchedule {
  const ProfileFixedSchedule({
    required this.id,
    required this.classTypeName,
    required this.trainerName,
    required this.dayOfWeek,
    required this.startsAtTime,
  });

  final int id;
  final String classTypeName;
  final String trainerName;
  final int dayOfWeek;
  final String startsAtTime;
}
