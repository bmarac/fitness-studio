import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.memberId,
    required super.memberFirstName,
    required super.memberLastName,
    required super.classSessionId,
    required super.bookingSource,
    required super.memberFixedScheduleId,
    required super.status,
    required super.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as int,
      memberId: json['memberId'] as int,
      memberFirstName: json['memberFirstName'] as String,
      memberLastName: json['memberLastName'] as String,
      classSessionId: json['classSessionId'] as int,
      bookingSource: json['bookingSource'] as String,
      memberFixedScheduleId: json['memberFixedScheduleId'] as int?,
      status: json['status'] as String,
      bookedAt: DateTime.parse(json['bookedAt'] as String),
    );
  }
}
