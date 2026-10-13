import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/membership_plans/domain/entities/membership_plan.dart';
import 'package:fitness_studio_mobile/features/membership_plans/domain/repositories/membership_plans_repository.dart';
import 'package:fitness_studio_mobile/features/membership_plans/presentation/screens/membership_plans_screen.dart';
import 'package:fitness_studio_mobile/features/membership_plans/presentation/state/membership_plans_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows active, inactive, limited and unlimited plans', (
    tester,
  ) async {
    final repository = _FakeMembershipPlansRepository([
      _plan,
      const MembershipPlan(
        id: 2,
        name: 'Neograničeni',
        description: null,
        billingPeriodMonths: 1,
        sessionLimit: null,
        sessionLimitPeriod: null,
        priceAmount: 55,
        currency: 'EUR',
        status: 'inactive',
      ),
    ]);
    await _pump(tester, repository);

    expect(find.text('Mjesečni'), findsOneWidget);
    expect(find.text('Neograničeni'), findsOneWidget);
    expect(find.text('8 termina / Mjesec'), findsOneWidget);
    expect(find.text('Neograničen broj termina'), findsOneWidget);
    expect(find.text('Aktivan'), findsOneWidget);
    expect(find.text('Neaktivan'), findsOneWidget);
  });

  testWidgets('shows an empty state', (tester) async {
    await _pump(tester, _FakeMembershipPlansRepository([]));

    expect(find.text('Još nema paketa.'), findsOneWidget);
  });

  testWidgets('shows a localized load error and retries', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          membershipPlansProvider.overrideWith((ref) async {
            attempts += 1;
            if (attempts == 1) {
              throw const Failure(FailureKind.network);
            }
            return [_plan];
          }),
        ],
        child: localizedTestApp(home: const MembershipPlansScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mrežni zahtjev nije uspio.'), findsOneWidget);
    await tester.tap(find.text('Pokušaj ponovno'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Mjesečni'), findsOneWidget);
  });

  testWidgets('validates and creates a limited plan from the bottom sheet', (
    tester,
  ) async {
    final repository = _FakeMembershipPlansRepository([]);
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('add-membership-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-membership-plan')));
    await tester.pump();

    expect(find.text('Ovo polje je obvezno.'), findsOneWidget);
    expect(find.text('Unesi ispravnu nenegativnu cijenu.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('membership-plan-name')),
      'Novi paket',
    );
    await tester.enterText(
      find.byKey(const ValueKey('membership-plan-price')),
      '35,50',
    );
    await tester.tap(
      find.byKey(const ValueKey('membership-plan-limit-enabled')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('membership-plan-limit')),
      '6',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-membership-plan')),
    );
    await tester.tap(find.byKey(const ValueKey('save-membership-plan')));
    await tester.pumpAndSettle();

    expect(repository.created?.name, 'Novi paket');
    expect(repository.created?.priceAmount, 35.5);
    expect(repository.created?.sessionLimit, 6);
    expect(repository.created?.sessionLimitPeriod, 'month');
    expect(find.text('Paket je dodan.'), findsOneWidget);
  });

  testWidgets('edits an existing plan', (tester) async {
    final repository = _FakeMembershipPlansRepository([_plan]);
    await _pump(tester, repository);

    await tester.tap(find.text('Mjesečni'));
    await tester.pumpAndSettle();
    expect(find.text('Uredi paket'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('membership-plan-name')),
          )
          .controller!
          .text,
      'Mjesečni',
    );

    await tester.enterText(
      find.byKey(const ValueKey('membership-plan-price')),
      '45',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-membership-plan')),
    );
    await tester.tap(find.byKey(const ValueKey('save-membership-plan')));
    await tester.pumpAndSettle();

    expect(repository.updatedId, 1);
    expect(repository.updated?.priceAmount, 45);
    expect(find.text('Paket je spremljen.'), findsOneWidget);
  });

  testWidgets('deletes a plan after confirmation', (tester) async {
    final repository = _FakeMembershipPlansRepository([_plan]);
    await _pump(tester, repository);

    await _chooseDelete(tester);
    await tester.tap(
      find.byKey(const ValueKey('confirm-delete-membership-plan')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedId, 1);
    expect(find.text('Paket je obrisan.'), findsOneWidget);
  });

  testWidgets('offers deactivation when an assigned plan cannot be deleted', (
    tester,
  ) async {
    final repository = _FakeMembershipPlansRepository([_plan])
      ..deleteFailure = const Failure.remote('in use', statusCode: 409);
    await _pump(tester, repository);

    await _chooseDelete(tester);
    await tester.tap(
      find.byKey(const ValueKey('confirm-delete-membership-plan')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paket se ne može obrisati'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('deactivate-membership-plan')));
    await tester.pumpAndSettle();

    expect(repository.updatedId, 1);
    expect(repository.updated?.status, 'inactive');
    expect(find.text('Paket je označen neaktivnim.'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakeMembershipPlansRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        membershipPlansRepositoryProvider.overrideWithValue(repository),
        membershipPlansProvider.overrideWith((ref) async => repository.items),
      ],
      child: localizedTestApp(home: const MembershipPlansScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _chooseDelete(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('membership-plan-menu-1')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Obriši'));
  await tester.pumpAndSettle();
  expect(find.text('Obriši paket?'), findsOneWidget);
}

class _FakeMembershipPlansRepository implements MembershipPlansRepository {
  _FakeMembershipPlansRepository(this.items);

  final List<MembershipPlan> items;
  MembershipPlanDraft? created;
  MembershipPlanDraft? updated;
  int? updatedId;
  int? deletedId;
  Failure? deleteFailure;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() async => Success(items);

  @override
  Future<Result<MembershipPlan>> createPlan(MembershipPlanDraft draft) async {
    created = draft;
    final plan = MembershipPlan(
      id: 99,
      name: draft.name.trim(),
      description: draft.description,
      billingPeriodMonths: 1,
      sessionLimit: draft.sessionLimit,
      sessionLimitPeriod: draft.sessionLimitPeriod,
      priceAmount: draft.priceAmount,
      currency: 'EUR',
      status: draft.status,
    );
    items.add(plan);
    return Success(plan);
  }

  @override
  Future<Result<void>> updatePlan(int id, MembershipPlanDraft draft) async {
    updatedId = id;
    updated = draft;
    final index = items.indexWhere((item) => item.id == id);
    if (index != -1) {
      items[index] = MembershipPlan(
        id: id,
        name: draft.name.trim(),
        description: draft.description,
        billingPeriodMonths: 1,
        sessionLimit: draft.sessionLimit,
        sessionLimitPeriod: draft.sessionLimitPeriod,
        priceAmount: draft.priceAmount,
        currency: 'EUR',
        status: draft.status,
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deletePlan(int id) async {
    deletedId = id;
    final failure = deleteFailure;
    if (failure != null) return FailureResult(failure);
    items.removeWhere((item) => item.id == id);
    return const Success(null);
  }
}

const _plan = MembershipPlan(
  id: 1,
  name: 'Mjesečni',
  description: 'Osam termina',
  billingPeriodMonths: 1,
  sessionLimit: 8,
  sessionLimitPeriod: 'month',
  priceAmount: 40,
  currency: 'EUR',
  status: 'active',
);
