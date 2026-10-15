import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/trainers/data/trainers_management_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/trainers/data/trainers_management_repository_impl.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/entities/trainer_management.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps trainers and delegates individual CRUD operations', () async {
    final source = _FakeTrainersDataSource();
    final repository = TrainersManagementRepositoryImpl(source);

    final loaded = await repository.getTrainers();
    final trainer = (loaded as Success<List<TrainerSummary>>).value.single;
    expect(trainer.fullName, 'Filip Šarić');
    expect(trainer.phone, '+385 91 123 4567');
    expect(trainer.isActive, isTrue);

    const draft = TrainerDraft(
      firstName: ' Ana ',
      lastName: ' Horvat ',
      email: ' ANA@EXAMPLE.COM ',
      phone: ' ',
      bio: ' Mobilnost ',
      status: 'active',
    );
    final created = await repository.createTrainer(draft);
    expect((created as Success<TrainerSummary>).value.id, 3);
    expect(source.created?['firstName'], 'Ana');
    expect(source.created?['email'], 'ana@example.com');
    expect(source.created?['phone'], isNull);
    expect(source.created?['bio'], 'Mobilnost');

    await repository.updateTrainer(2, draft);
    expect(source.updatedId, 2);
    expect(source.updated?['status'], 'active');

    await repository.deleteTrainer(2);
    expect(source.deletedId, 2);
  });
}

class _FakeTrainersDataSource implements TrainersManagementDataSource {
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  int? updatedId;
  int? deletedId;

  @override
  Future<List<dynamic>> getTrainers() async => [_json(2, 'Filip', 'Šarić')];

  @override
  Future<Map<String, dynamic>> createTrainer(Map<String, dynamic> data) async {
    created = data;
    return _json(3, data['firstName'] as String, data['lastName'] as String);
  }

  @override
  Future<void> updateTrainer(int id, Map<String, dynamic> data) async {
    updatedId = id;
    updated = data;
  }

  @override
  Future<void> deleteTrainer(int id) async {
    deletedId = id;
  }

  Map<String, dynamic> _json(int id, String firstName, String lastName) => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': '${firstName.toLowerCase()}@example.com',
    'phone': '+385 91 123 4567',
    'bio': 'Trener snage',
    'status': 'active',
  };
}
