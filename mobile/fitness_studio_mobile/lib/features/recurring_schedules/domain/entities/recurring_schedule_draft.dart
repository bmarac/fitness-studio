class RecurringScheduleDraft {
  const RecurringScheduleDraft({
    required this.classTypeId,
    required this.trainerId,
    required this.dayOfWeek,
    required this.startsAtTime,
    required this.durationMinutes,
    required this.capacity,
    required this.validFrom,
  });

  final int classTypeId;
  final int trainerId;
  final int dayOfWeek;
  final DateTime startsAtTime;
  final int durationMinutes;
  final int capacity;
  final DateTime validFrom;
}
