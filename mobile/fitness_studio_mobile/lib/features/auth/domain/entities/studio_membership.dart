class StudioMembership {
  const StudioMembership({
    required this.studioId,
    required this.studioName,
    required this.memberId,
    required this.trainerId,
    required this.roles,
  });

  final int studioId;
  final String studioName;
  final int? memberId;
  final int? trainerId;
  final List<String> roles;
}

class StudioLookup {
  const StudioLookup({
    required this.studioId,
    required this.studioName,
    required this.requiresProfileDetails,
    required this.role,
  });

  final int studioId;
  final String studioName;
  final bool requiresProfileDetails;
  final String role;
}
