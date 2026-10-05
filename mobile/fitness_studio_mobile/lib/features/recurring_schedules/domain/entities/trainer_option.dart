class TrainerOption {
  const TrainerOption({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final int id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName';
}
