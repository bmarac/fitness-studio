import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/entities/trainer_management.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/repositories/trainers_management_repository.dart';
import 'package:fitness_studio_mobile/features/trainers/presentation/screens/trainers_screen.dart';
import 'package:fitness_studio_mobile/features/trainers/presentation/state/trainers_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows trainer details and opens edit modal', (tester) async {
    final repository = _FakeTrainersRepository([_filip]);
    await _pump(tester, repository);

    expect(find.text('Filip Šarić'), findsOneWidget);
    expect(find.text('filip@example.com'), findsOneWidget);
    expect(find.text('+385 91 123 4567'), findsOneWidget);
    expect(find.text('Trener snage'), findsOneWidget);
    expect(find.text('Aktivan'), findsOneWidget);

    await tester.tap(find.text('Filip Šarić'));
    await tester.pumpAndSettle();
    expect(find.text('Uredi trenera'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Marko');
    await tester.ensureVisible(find.byKey(const ValueKey('save-trainer')));
    await tester.tap(find.byKey(const ValueKey('save-trainer')));
    await tester.pumpAndSettle();

    expect(repository.updatedId, 2);
    expect(repository.updated?.firstName, 'Marko');
    expect(find.text('Trener je ažuriran.'), findsOneWidget);
  });

  testWidgets('validates and creates a trainer', (tester) async {
    final repository = _FakeTrainersRepository([]);
    await _pump(tester, repository);

    expect(find.text('Još nema trenera.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-trainer')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-trainer')));
    await tester.tap(find.byKey(const ValueKey('save-trainer')));
    await tester.pump();

    expect(find.text('Ovo polje je obvezno.'), findsNWidgets(3));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' Ana ');
    await tester.enterText(fields.at(1), ' Horvat ');
    await tester.enterText(fields.at(2), ' ANA@EXAMPLE.COM ');
    await tester.ensureVisible(find.byKey(const ValueKey('save-trainer')));
    await tester.tap(find.byKey(const ValueKey('save-trainer')));
    await tester.pumpAndSettle();

    expect(repository.created?.firstName, ' Ana ');
    expect(repository.created?.status, 'active');
    expect(find.text('Trener je dodan.'), findsOneWidget);
  });

  testWidgets('offers deactivation when an active trainer is in use', (
    tester,
  ) async {
    final repository = _FakeTrainersRepository(
      [_filip],
      deleteResult: const FailureResult(
        Failure.remote('Trainer is in use.', statusCode: 409),
      ),
    );
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('trainer-menu-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obriši'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-trainer')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Trenera s povezanim terminima nije moguće ukloniti. '
        'Označi ga neaktivnim.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('deactivate-trainer')));
    await tester.pumpAndSettle();

    expect(repository.updated?.status, 'inactive');
    expect(find.text('Trener je označen neaktivnim.'), findsOneWidget);
  });

  testWidgets('shows a localized load error and retries', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          managedTrainersProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) throw const Failure(FailureKind.network);
            return [_filip];
          }),
        ],
        child: localizedTestApp(home: const TrainersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mrežni zahtjev nije uspio.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovno'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Filip Šarić'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  TrainersManagementRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trainersManagementRepositoryProvider.overrideWithValue(repository),
      ],
      child: localizedTestApp(home: const TrainersScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeTrainersRepository implements TrainersManagementRepository {
  _FakeTrainersRepository(
    List<TrainerSummary> trainers, {
    this.deleteResult = const Success(null),
  }) : trainers = [...trainers];

  final List<TrainerSummary> trainers;
  final Result<void> deleteResult;
  TrainerDraft? created;
  TrainerDraft? updated;
  int? updatedId;

  @override
  Future<Result<List<TrainerSummary>>> getTrainers() async => Success(trainers);

  @override
  Future<Result<TrainerSummary>> createTrainer(TrainerDraft draft) async {
    created = draft;
    final trainer = TrainerSummary(
      id: 3,
      firstName: draft.firstName.trim(),
      lastName: draft.lastName.trim(),
      email: draft.email.trim().toLowerCase(),
      phone: draft.phone,
      bio: draft.bio,
      status: draft.status,
    );
    trainers.add(trainer);
    return Success(trainer);
  }

  @override
  Future<Result<void>> updateTrainer(int id, TrainerDraft draft) async {
    updatedId = id;
    updated = draft;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteTrainer(int id) async => deleteResult;
}

const _filip = TrainerSummary(
  id: 2,
  firstName: 'Filip',
  lastName: 'Šarić',
  email: 'filip@example.com',
  phone: '+385 91 123 4567',
  bio: 'Trener snage',
  status: 'active',
);
