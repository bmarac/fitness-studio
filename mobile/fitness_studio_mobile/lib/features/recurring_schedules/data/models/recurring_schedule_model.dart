import '../../domain/entities/recurring_schedule.dart';

class RecurringScheduleModel extends RecurringSchedule {
  const RecurringScheduleModel({
    required super.id,
    required super.classTypeName,
    required super.trainerId,
    required super.trainerName,
    required super.dayOfWeek,
    required super.startsAtTime,
    required super.validFrom,
    required super.validUntil,
    required super.status,
    required super.statusEffectiveFrom,
  });

  factory RecurringScheduleModel.fromJson(Map<String, dynamic> json) {
    return RecurringScheduleModel(
      id: json['id'] as int,
      classTypeName: json['classTypeName'] as String,
      trainerId: json['trainerId'] as int,
      trainerName: json['trainerName'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startsAtTime: json['startsAtTime'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: json['validUntil'] == null
          ? null
          : DateTime.parse(json['validUntil'] as String),
      status: json['status'] as String,
      statusEffectiveFrom: json['statusEffectiveFrom'] == null
          ? null
          : DateTime.parse(json['statusEffectiveFrom'] as String),
    );
  }
}
