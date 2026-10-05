import '../../domain/entities/class_session.dart';

class ClassSessionModel extends ClassSession {
  const ClassSessionModel({
    required super.id,
    required super.classTypeId,
    required super.classTypeName,
    required super.trainerId,
    required super.trainerFirstName,
    required super.trainerLastName,
    required super.startsAt,
    required super.endsAt,
    required super.capacity,
    required super.bookedCount,
    required super.status,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    return ClassSessionModel(
      id: json['id'] as int,
      classTypeId: json['classTypeId'] as int,
      classTypeName: json['classTypeName'] as String,
      trainerId: json['trainerId'] as int,
      trainerFirstName: json['trainerFirstName'] as String,
      trainerLastName: json['trainerLastName'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      capacity: json['capacity'] as int,
      bookedCount: json['bookedCount'] as int,
      status: json['status'] as String,
    );
  }
}
