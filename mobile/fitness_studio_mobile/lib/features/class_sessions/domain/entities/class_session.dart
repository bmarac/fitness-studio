class ClassSession {
  const ClassSession({
    required this.id,
    required this.classTypeId,
    required this.classTypeName,
    required this.trainerId,
    required this.trainerFirstName,
    required this.trainerLastName,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.bookedCount,
    required this.status,
  });

  final int id;
  final int classTypeId;
  final String classTypeName;
  final int trainerId;
  final String trainerFirstName;
  final String trainerLastName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int bookedCount;
  final String status;

  String get trainerFullName => '$trainerFirstName $trainerLastName';

  int get durationMinutes => endsAt.difference(startsAt).inMinutes;
}
