import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/class_types/domain/entities/class_type.dart';
import 'package:fitness_studio_mobile/features/class_types/domain/repositories/class_types_repository.dart';
import 'package:fitness_studio_mobile/features/class_types/presentation/screens/class_types_screen.dart';
import 'package:fitness_studio_mobile/features/class_types/presentation/state/class_types_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows class type details and opens edit modal', (tester) async {
    final repository = _FakeClassTypesRepository([_pilates]);
    await _pump(tester, repository);

    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('60 min · kapacitet 10'), findsOneWidget);
    expect(find.text('Sve razine'), findsOneWidget);
    expect(find.text('Aktivan'), findsOneWidget);

    await tester.tap(find.text('Pilates'));
    await tester.pumpAndSettle();
    expect(find.text('Uredi vrstu treninga'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Power Pilates');
    await tester.ensureVisible(find.byKey(const ValueKey('save-class-type')));
    await tester.tap(find.byKey(const ValueKey('save-class-type')));
    await tester.pumpAndSettle();

    expect(repository.updatedId, 1);
    expect(repository.updated?.name, 'Power Pilates');
    expect(find.text('Vrsta treninga je ažurirana.'), findsOneWidget);
  });

  testWidgets('validates and creates a class type', (tester) async {
    final repository = _FakeClassTypesRepository([]);
    await _pump(tester, repository);

    expect(find.text('Još nema vrsta treninga.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-class-type')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.tap(find.byKey(const ValueKey('save-class-type')));
    await tester.pump();

    expect(find.text('Ovo polje je obvezno.'), findsOneWidget);
    expect(find.text('Unesi broj veći od 0.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Yoga');
    await tester.enterText(find.byType(TextFormField).at(2), '45');
    await tester.tap(find.byKey(const ValueKey('save-class-type')));
    await tester.pumpAndSettle();

    expect(repository.created?.name, 'Yoga');
    expect(repository.created?.defaultDurationMinutes, 45);
    expect(find.text('Vrsta treninga je dodana.'), findsOneWidget);
  });

  testWidgets('offers deactivation when an active class type is in use', (
    tester,
  ) async {
    final repository = _FakeClassTypesRepository(
      [_pilates],
      deleteResult: const FailureResult(
        Failure.remote('Class type is in use.', statusCode: 409),
      ),
    );
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('class-type-menu-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Obriši'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete-class-type')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Korištenu vrstu treninga nije moguće ukloniti. '
        'Označi je neaktivnom.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('deactivate-class-type')));
    await tester.pumpAndSettle();

    expect(repository.updated?.status, 'inactive');
    expect(find.text('Vrsta treninga je označena neaktivnom.'), findsOneWidget);
  });

  testWidgets('shows a localized load error and retries', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          classTypesProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) throw const Failure(FailureKind.network);
            return [_pilates];
          }),
        ],
        child: localizedTestApp(home: const ClassTypesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mrežni zahtjev nije uspio.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovno'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Pilates'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, ClassTypesRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [classTypesRepositoryProvider.overrideWithValue(repository)],
      child: localizedTestApp(home: const ClassTypesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeClassTypesRepository implements ClassTypesRepository {
  _FakeClassTypesRepository(
    List<ClassType> items, {
    this.deleteResult = const Success(null),
  }) : items = [...items];

  final List<ClassType> items;
  final Result<void> deleteResult;
  ClassTypeDraft? created;
  ClassTypeDraft? updated;
  int? updatedId;

  @override
  Future<Result<List<ClassType>>> getClassTypes() async => Success(items);

  @override
  Future<Result<ClassType>> createClassType(ClassTypeDraft draft) async {
    created = draft;
    final item = ClassType(
      id: 2,
      name: draft.name,
      description: draft.description,
      defaultDurationMinutes: draft.defaultDurationMinutes,
      defaultCapacity: draft.defaultCapacity,
      difficultyLevel: draft.difficultyLevel,
      status: draft.status,
    );
    items.add(item);
    return Success(item);
  }

  @override
  Future<Result<void>> updateClassType(int id, ClassTypeDraft draft) async {
    updatedId = id;
    updated = draft;
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteClassType(int id) async => deleteResult;
}

const _pilates = ClassType(
  id: 1,
  name: 'Pilates',
  description: 'Kontrolirani pokreti.',
  defaultDurationMinutes: 60,
  defaultCapacity: 10,
  difficultyLevel: 'all_levels',
  status: 'active',
);
