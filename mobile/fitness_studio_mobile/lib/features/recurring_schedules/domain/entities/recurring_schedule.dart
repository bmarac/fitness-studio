class RecurringSchedule {
  const RecurringSchedule({
    required this.id,
    required this.classTypeName,
    required this.trainerId,
    required this.trainerName,
    required this.dayOfWeek,
    required this.startsAtTime,
    required this.durationMinutes,
    required this.capacity,
    required this.activeMemberCount,
    required this.validFrom,
    required this.validUntil,
    required this.status,
    required this.statusEffectiveFrom,
  });

  final int id;
  final String classTypeName;
  final int trainerId;
  final String trainerName;
  final int dayOfWeek;
  final String startsAtTime;
  final int durationMinutes;
  final int capacity;
  final int activeMemberCount;
  final DateTime validFrom;
  final DateTime? validUntil;
  final String status;
  final DateTime? statusEffectiveFrom;
}
