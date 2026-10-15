class TrainerSummary {
  const TrainerSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.bio,
    required this.status,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? bio;
  final String status;

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';

  TrainerDraft toDraft({String? status}) => TrainerDraft(
    firstName: firstName,
    lastName: lastName,
    email: email,
    phone: phone,
    bio: bio,
    status: status ?? this.status,
  );
}

class TrainerDraft {
  const TrainerDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.bio,
    required this.status,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? bio;
  final String status;
}
