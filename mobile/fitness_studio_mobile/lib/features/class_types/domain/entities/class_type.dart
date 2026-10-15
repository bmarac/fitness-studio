class ClassType {
  const ClassType({
    required this.id,
    required this.name,
    this.description,
    required this.defaultDurationMinutes,
    required this.defaultCapacity,
    required this.difficultyLevel,
    required this.status,
  });

  final int id;
  final String name;
  final String? description;
  final int defaultDurationMinutes;
  final int defaultCapacity;
  final String difficultyLevel;
  final String status;

  bool get isActive => status == 'active';

  ClassTypeDraft toDraft({String? status}) => ClassTypeDraft(
    name: name,
    description: description,
    defaultDurationMinutes: defaultDurationMinutes,
    defaultCapacity: defaultCapacity,
    difficultyLevel: difficultyLevel,
    status: status ?? this.status,
  );
}

class ClassTypeDraft {
  const ClassTypeDraft({
    required this.name,
    this.description,
    required this.defaultDurationMinutes,
    required this.defaultCapacity,
    required this.difficultyLevel,
    required this.status,
  });

  final String name;
  final String? description;
  final int defaultDurationMinutes;
  final int defaultCapacity;
  final String difficultyLevel;
  final String status;
}
