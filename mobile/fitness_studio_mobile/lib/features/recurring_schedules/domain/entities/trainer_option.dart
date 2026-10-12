class TrainerOption {
  const TrainerOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.status,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String status;

  String get fullName => '$firstName $lastName';
}
