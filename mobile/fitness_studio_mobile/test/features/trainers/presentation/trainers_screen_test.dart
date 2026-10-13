import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/entities/trainer_management.dart';
import 'package:fitness_studio_mobile/features/trainers/domain/repositories/trainers_management_repository.dart';
import 'package:fitness_studio_mobile/features/trainers/presentation/screens/trainers_screen.dart';
import 'package:fitness_studio_mobile/features/trainers/presentation/state/trainers_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows trainers without member controls', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainersManagementRepositoryProvider.overrideWithValue(
            _Repository(
              trainers: const [
                TrainerSummary(
                  id: 2,
                  firstName: 'Filip',
                  lastName: 'Šarić',
                  email: 'filip@example.com',
                ),
              ],
            ),
          ),
        ],
        child: localizedTestApp(home: const TrainersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Treneri'), findsOneWidget);
    expect(find.text('Filip Šarić'), findsOneWidget);
    expect(find.text('Novi trener'), findsOneWidget);
    expect(find.text('Članovi'), findsNothing);
    expect(find.text('Novi član'), findsNothing);
  });

  testWidgets('shows trainer-specific empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainersManagementRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: localizedTestApp(home: const TrainersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Još nema trenera.'), findsOneWidget);
  });

  testWidgets('validates and submits the trainer form', (tester) async {
    final repository = _Repository();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/novi-trener',
          builder: (_, _) => const CreateTrainerScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trainersManagementRepositoryProvider.overrideWithValue(repository),
        ],
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/novi-trener');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spremi'));
    await tester.pump();
    expect(find.text('Ovo polje je obvezno.'), findsNWidgets(3));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' Filip ');
    await tester.enterText(fields.at(1), ' Šarić ');
    await tester.enterText(fields.at(2), ' FILIP@EXAMPLE.COM ');
    await tester.enterText(fields.at(3), '+385 91 123 4567');
    await tester.enterText(fields.at(4), ' Trener snage ');
    await tester.tap(find.text('Spremi'));
    await tester.pumpAndSettle();

    expect(repository.created?.firstName, ' Filip ');
    expect(repository.created?.email, ' FILIP@EXAMPLE.COM ');
    expect(router.routeInformationProvider.value.uri.path, '/');
  });
}

class _Repository implements TrainersManagementRepository {
  _Repository({this.trainers = const []});

  final List<TrainerSummary> trainers;
  TrainerDraft? created;

  @override
  Future<Result<List<TrainerSummary>>> getTrainers() async => Success(trainers);

  @override
  Future<Result<TrainerSummary>> createTrainer(TrainerDraft draft) async {
    created = draft;
    return Success(
      TrainerSummary(
        id: 3,
        firstName: draft.firstName.trim(),
        lastName: draft.lastName.trim(),
        email: draft.email.trim().toLowerCase(),
      ),
    );
  }
}
