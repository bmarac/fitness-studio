import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/class_types/data/class_types_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_types/data/class_types_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_types/domain/entities/class_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps class types and delegates individual CRUD operations', () async {
    final source = _FakeClassTypesDataSource();
    final repository = ClassTypesRepositoryImpl(source);

    final loaded = await repository.getClassTypes();
    expect((loaded as Success<List<ClassType>>).value.single.name, 'Pilates');

    const draft = ClassTypeDraft(
      name: ' Yoga ',
      description: '  Mobilnost  ',
      defaultDurationMinutes: 45,
      defaultCapacity: 8,
      difficultyLevel: 'beginner',
      status: 'active',
    );
    final created = await repository.createClassType(draft);
    expect((created as Success<ClassType>).value.id, 2);
    expect(source.created?['name'], 'Yoga');
    expect(source.created?['description'], 'Mobilnost');

    await repository.updateClassType(1, draft);
    expect(source.updatedId, 1);
    expect(source.updated?['defaultDurationMinutes'], 45);

    await repository.deleteClassType(1);
    expect(source.deletedId, 1);
  });
}

class _FakeClassTypesDataSource implements ClassTypesDataSource {
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  int? updatedId;
  int? deletedId;

  @override
  Future<List<dynamic>> getClassTypes() async => [_json(1, 'Pilates')];

  @override
  Future<Map<String, dynamic>> createClassType(
    Map<String, dynamic> data,
  ) async {
    created = data;
    return _json(2, data['name'] as String);
  }

  @override
  Future<void> updateClassType(int id, Map<String, dynamic> data) async {
    updatedId = id;
    updated = data;
  }

  @override
  Future<void> deleteClassType(int id) async {
    deletedId = id;
  }

  Map<String, dynamic> _json(int id, String name) => {
    'id': id,
    'name': name,
    'description': null,
    'defaultDurationMinutes': 60,
    'defaultCapacity': 10,
    'difficultyLevel': 'all_levels',
    'status': 'active',
  };
}
