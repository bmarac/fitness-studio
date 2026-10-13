import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/screens/class_session_details_screen.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_session_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows booking availability without occupancy details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_FakeLoginController.new),
          classSessionDetailsProvider.overrideWith(
            (ref, id) async => _session(bookedCount: 3),
          ),
        ],
        child: localizedTestApp(
          home: const ClassSessionDetailsScreen(classSessionId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rezervacija'), findsOneWidget);
    expect(find.text('Dostupna'), findsOneWidget);
    expect(find.text('Popunjenost'), findsNothing);
    expect(find.text('3/12 rezervirano'), findsNothing);
  });

  testWidgets('shows booking as unavailable when the class is full', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_FakeLoginController.new),
          classSessionDetailsProvider.overrideWith(
            (ref, id) async => _session(bookedCount: 12),
          ),
        ],
        child: localizedTestApp(
          home: const ClassSessionDetailsScreen(classSessionId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nije dostupna'), findsOneWidget);
  });

  testWidgets('disables booking after the class start time', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_FakeLoginController.new),
          classSessionDetailsProvider.overrideWith(
            (ref, id) async =>
                _session(bookedCount: 3, startsAt: DateTime(2020, 10, 16, 10)),
          ),
        ],
        child: localizedTestApp(
          home: const ClassSessionDetailsScreen(classSessionId: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nije dostupna'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}

class _FakeLoginController extends LoginController {
  @override
  LoginState build() => LoginSuccess(
    AuthSession(
      accessToken: 'token',
      expiresAt: DateTime(2031),
      user: const AuthenticatedUser(
        id: 1,
        studioId: 1,
        memberId: 10,
        trainerId: null,
        email: 'member@example.com',
        roles: ['member'],
      ),
    ),
  );
}

ClassSession _session({required int bookedCount, DateTime? startsAt}) =>
    ClassSession(
      id: 1,
      classTypeId: 1,
      classTypeName: 'Pilates',
      trainerId: 2,
      trainerFirstName: 'Filip',
      trainerLastName: 'Šarić',
      startsAt: startsAt ?? DateTime(2030, 10, 16, 10),
      endsAt: (startsAt ?? DateTime(2030, 10, 16, 10)).add(
        const Duration(hours: 1),
      ),
      capacity: 12,
      bookedCount: bookedCount,
      status: 'scheduled',
      recurringScheduleId: null,
      recurringScheduleStatus: null,
    );
