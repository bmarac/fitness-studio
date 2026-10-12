class Booking {
  const Booking({
    required this.id,
    required this.memberId,
    required this.memberFirstName,
    required this.memberLastName,
    required this.classSessionId,
    required this.bookingSource,
    required this.memberFixedScheduleId,
    required this.classTypeId,
    required this.classTypeName,
    required this.trainerId,
    required this.trainerFirstName,
    required this.trainerLastName,
    required this.classSessionStartsAt,
    required this.classSessionEndsAt,
    required this.status,
    required this.bookedAt,
    required this.cancelledAt,
    required this.attendedAt,
  });

  final int id;
  final int memberId;
  final String memberFirstName;
  final String memberLastName;
  final int classSessionId;
  final String bookingSource;
  final int? memberFixedScheduleId;
  final int classTypeId;
  final String classTypeName;
  final int trainerId;
  final String trainerFirstName;
  final String trainerLastName;
  final DateTime classSessionStartsAt;
  final DateTime classSessionEndsAt;
  final String status;
  final DateTime bookedAt;
  final DateTime? cancelledAt;
  final DateTime? attendedAt;

  String get memberFullName => '$memberFirstName $memberLastName';

  String get trainerFullName => '$trainerFirstName $trainerLastName';

  bool canMemberCancel(DateTime now) =>
      (status == 'booked' || status == 'waitlisted') &&
      classSessionStartsAt.isAfter(now);
}
