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
    required super.classTypeId,
    required super.classTypeName,
    required super.trainerId,
    required super.trainerFirstName,
    required super.trainerLastName,
    required super.classSessionStartsAt,
    required super.classSessionEndsAt,
    required super.status,
    required super.bookedAt,
    required super.cancelledAt,
    required super.attendedAt,
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
      classTypeId: json['classTypeId'] as int,
      classTypeName: json['classTypeName'] as String,
      trainerId: json['trainerId'] as int,
      trainerFirstName: json['trainerFirstName'] as String,
      trainerLastName: json['trainerLastName'] as String,
      classSessionStartsAt: DateTime.parse(
        json['classSessionStartsAt'] as String,
      ).toLocal(),
      classSessionEndsAt: DateTime.parse(
        json['classSessionEndsAt'] as String,
      ).toLocal(),
      status: json['status'] as String,
      bookedAt: DateTime.parse(json['bookedAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      attendedAt: json['attendedAt'] == null
          ? null
          : DateTime.parse(json['attendedAt'] as String),
    );
  }
}
