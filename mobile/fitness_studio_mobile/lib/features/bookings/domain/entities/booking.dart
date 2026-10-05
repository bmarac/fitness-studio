class Booking {
  const Booking({
    required this.id,
    required this.memberId,
    required this.memberFirstName,
    required this.memberLastName,
    required this.classSessionId,
    required this.bookingSource,
    required this.memberFixedScheduleId,
    required this.status,
    required this.bookedAt,
  });

  final int id;
  final int memberId;
  final String memberFirstName;
  final String memberLastName;
  final int classSessionId;
  final String bookingSource;
  final int? memberFixedScheduleId;
  final String status;
  final DateTime bookedAt;

  String get memberFullName => '$memberFirstName $memberLastName';
}
