import '../../domain/entities/class_type_option.dart';

class ClassTypeOptionModel extends ClassTypeOption {
  const ClassTypeOptionModel({
    required super.id,
    required super.name,
    required super.defaultDurationMinutes,
    required super.defaultCapacity,
  });

  factory ClassTypeOptionModel.fromJson(Map<String, dynamic> json) {
    return ClassTypeOptionModel(
      id: json['id'] as int,
      name: json['name'] as String,
      defaultDurationMinutes: json['defaultDurationMinutes'] as int,
      defaultCapacity: json['defaultCapacity'] as int,
    );
  }
}
