class ScheduleMemberOption {
  const ScheduleMemberOption({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String status;

  String get fullName => '$firstName $lastName';
}
