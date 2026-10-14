import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/features/member_packages/domain/entities/member_package.dart';
import 'package:fitness_studio_mobile/features/member_packages/domain/repositories/member_packages_repository.dart';
import 'package:fitness_studio_mobile/features/member_packages/presentation/screens/member_packages_screen.dart';
import 'package:fitness_studio_mobile/features/member_packages/presentation/state/member_packages_providers.dart';
import 'package:fitness_studio_mobile/features/membership_plans/domain/entities/membership_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets(
    'prioritizes members without packages and supports quick filter',
    (tester) async {
      await _pump(tester, _Repository());

      expect(find.text('Ana Horvat'), findsOneWidget);
      expect(find.text('Ivan Ivić'), findsOneWidget);
      expect(find.text('Mia Radić'), findsOneWidget);
      expect(find.text('Mjesečni'), findsOneWidget);
      expect(find.text('Nema aktivnog paketa'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Mia Radić')).dy,
        lessThan(tester.getTopLeft(find.text('Ana Horvat')).dy),
      );
      expect(find.text('Bez paketa (1)'), findsOneWidget);
      final inactiveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('manage-member-package-8')),
      );
      expect(inactiveButton.onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('member-packages-filter-missing')),
      );
      await tester.pump();

      expect(find.text('Mia Radić'), findsOneWidget);
      expect(find.text('Ana Horvat'), findsNothing);
      expect(find.text('Ivan Ivić'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('member-packages-filter-all')),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('member-packages-search')),
        'ana@example',
      );
      await tester.pump();

      expect(find.text('Ana Horvat'), findsOneWidget);
      expect(find.text('Ivan Ivić'), findsNothing);
    },
  );

  testWidgets('assigns an active plan and excludes inactive plans', (
    tester,
  ) async {
    final repository = _Repository(includeMembership: false);
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('manage-member-package-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('member-package-plan')));
    await tester.pumpAndSettle();

    expect(find.text('Arhivski'), findsNothing);
    await tester.tap(find.text('Premium').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member-package')));
    await tester.pumpAndSettle();

    expect(repository.assigned?.memberId, 7);
    expect(repository.assigned?.membershipPlanId, 2);
    expect(repository.assigned?.endsOn, isNull);
    expect(find.textContaining('Paket za člana Ana Horvat'), findsOneWidget);
  });

  testWidgets('changes a package while preserving membership dates', (
    tester,
  ) async {
    final repository = _Repository();
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('manage-member-package-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('member-package-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Premium').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member-package')));
    await tester.pumpAndSettle();

    expect(repository.changedId, 31);
    expect(repository.changed?.membershipPlanId, 2);
    expect(repository.changed?.startsOn, DateTime(2026, 10, 1));
    expect(repository.changed?.endsOn, DateTime(2027, 1, 1));
  });

  testWidgets('validates dates before saving', (tester) async {
    final repository = _Repository(invalidDates: true);
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('manage-member-package-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member-package')));
    await tester.pump();

    expect(
      find.text('Datum završetka mora biti nakon datuma početka.'),
      findsOneWidget,
    );
    expect(repository.changed, isNull);
  });

  testWidgets('shows a localized repository error', (tester) async {
    final repository = _Repository(
      includeMembership: false,
      failure: const Failure(FailureKind.network),
    );
    await _pump(tester, repository);

    await tester.tap(find.byKey(const ValueKey('manage-member-package-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('member-package-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mjesečni').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-member-package')));
    await tester.pump();

    expect(find.text('Mrežni zahtjev nije uspio.'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, _Repository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memberPackagesRepositoryProvider.overrideWithValue(repository),
        memberPackagesProvider.overrideWith((ref) async => repository.overview),
      ],
      child: localizedTestApp(home: const MemberPackagesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _Repository implements MemberPackagesRepository {
  _Repository({
    this.includeMembership = true,
    this.invalidDates = false,
    this.failure,
  });

  final bool includeMembership;
  final bool invalidDates;
  final Failure? failure;
  MemberMembershipDraft? assigned;
  MemberMembershipDraft? changed;
  int? changedId;

  MemberPackageOverview get overview => MemberPackageOverview(
    members: const [
      PackageMember(
        id: 7,
        firstName: 'Ana',
        lastName: 'Horvat',
        email: 'ana@example.com',
        status: 'active',
      ),
      PackageMember(
        id: 8,
        firstName: 'Ivan',
        lastName: 'Ivić',
        email: 'ivan@example.com',
        status: 'inactive',
      ),
      PackageMember(
        id: 9,
        firstName: 'Mia',
        lastName: 'Radić',
        email: 'mia@example.com',
        status: 'active',
      ),
    ],
    memberships: includeMembership
        ? [
            MemberMembership(
              id: 31,
              memberId: 7,
              membershipPlanId: 1,
              membershipPlanName: 'Mjesečni',
              startsOn: DateTime(2026, 10, 1),
              endsOn: invalidDates
                  ? DateTime(2026, 9, 30)
                  : DateTime(2027, 1, 1),
              billingStartsOn: DateTime(2026, 10, 1),
              nextBillingOn: DateTime(2026, 11, 1),
              isActive: true,
            ),
          ]
        : const [],
    plans: const [
      MembershipPlan(
        id: 1,
        name: 'Mjesečni',
        description: null,
        billingPeriodMonths: 1,
        sessionLimit: 8,
        sessionLimitPeriod: 'month',
        priceAmount: 40,
        currency: 'EUR',
        status: 'active',
      ),
      MembershipPlan(
        id: 2,
        name: 'Premium',
        description: null,
        billingPeriodMonths: 1,
        sessionLimit: null,
        sessionLimitPeriod: null,
        priceAmount: 60,
        currency: 'EUR',
        status: 'active',
      ),
      MembershipPlan(
        id: 3,
        name: 'Arhivski',
        description: null,
        billingPeriodMonths: 1,
        sessionLimit: 4,
        sessionLimitPeriod: 'month',
        priceAmount: 30,
        currency: 'EUR',
        status: 'inactive',
      ),
    ],
  );

  @override
  Future<Result<void>> assignPackage(MemberMembershipDraft draft) async {
    if (failure case final failure?) return FailureResult(failure);
    assigned = draft;
    return const Success(null);
  }

  @override
  Future<Result<void>> changePackage(
    int membershipId,
    MemberMembershipDraft draft,
  ) async {
    if (failure case final failure?) return FailureResult(failure);
    changedId = membershipId;
    changed = draft;
    return const Success(null);
  }

  @override
  Future<Result<MemberPackageOverview>> getOverview() async =>
      Success(overview);
}
