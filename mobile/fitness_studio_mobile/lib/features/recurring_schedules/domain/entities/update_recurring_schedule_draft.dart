class UpdateRecurringScheduleDraft {
  const UpdateRecurringScheduleDraft({
    required this.trainerId,
    required this.dayOfWeek,
    required this.startsAtTime,
    required this.capacity,
    required this.effectiveFrom,
  });

  final int trainerId;
  final int dayOfWeek;
  final DateTime startsAtTime;
  final int capacity;
  final DateTime effectiveFrom;
}
