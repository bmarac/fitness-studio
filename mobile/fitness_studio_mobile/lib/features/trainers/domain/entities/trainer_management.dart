class TrainerSummary {
  const TrainerSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;

  String get fullName => '$firstName $lastName';
}

class TrainerDraft {
  const TrainerDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.bio,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? bio;
}
