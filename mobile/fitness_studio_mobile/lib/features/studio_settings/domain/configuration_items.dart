class ClassTypeConfiguration {
  const ClassTypeConfiguration({
    this.id,
    required this.name,
    this.description,
    required this.defaultDurationMinutes,
    required this.defaultCapacity,
    required this.difficultyLevel,
    required this.status,
  });

  final int? id;
  final String name;
  final String? description;
  final int defaultDurationMinutes;
  final int defaultCapacity;
  final String difficultyLevel;
  final String status;
}
