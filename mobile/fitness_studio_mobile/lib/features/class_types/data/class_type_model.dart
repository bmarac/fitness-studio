import '../domain/entities/class_type.dart';

class ClassTypeModel {
  const ClassTypeModel._();

  static ClassType fromJson(Map<String, dynamic> json) => ClassType(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    description: json['description'] as String?,
    defaultDurationMinutes: (json['defaultDurationMinutes'] as num).toInt(),
    defaultCapacity: (json['defaultCapacity'] as num).toInt(),
    difficultyLevel: json['difficultyLevel'] as String,
    status: json['status'] as String,
  );

  static Map<String, dynamic> draftToJson(ClassTypeDraft draft) => {
    'name': draft.name.trim(),
    'description': _optional(draft.description),
    'defaultDurationMinutes': draft.defaultDurationMinutes,
    'defaultCapacity': draft.defaultCapacity,
    'difficultyLevel': draft.difficultyLevel,
    'status': draft.status,
  };

  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
