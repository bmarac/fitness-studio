class ClassTypeOption {
  const ClassTypeOption({
    required this.id,
    required this.name,
    required this.defaultDurationMinutes,
    required this.defaultCapacity,
  });

  final int id;
  final String name;
  final int defaultDurationMinutes;
  final int defaultCapacity;
}
