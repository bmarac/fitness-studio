import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/screens/class_sessions_screen.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_controller.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('opens with today selected and aligned to the viewport top', (
    tester,
  ) async {
    final today = DateTime(2030, 10, 16);

    await _pumpScreen(tester, today);

    expect(_isSelected(tester, today), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(today))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
  });

  testWidgets('can align Sunday to the top and scroll back to earlier days', (
    tester,
  ) async {
    final sunday = DateTime(2030, 10, 13);

    await _pumpScreen(tester, sunday);

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final initialOffset = scrollView.controller!.offset;

    expect(_isSelected(tester, sunday), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(sunday))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
    expect(initialOffset, greaterThan(0));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(scrollView.controller!.offset, lessThan(initialOffset));
    expect(_isSelected(tester, sunday), isFalse);
  });

  testWidgets('updates the selected day while scrolling', (tester) async {
    final today = DateTime(2030, 10, 16);

    await _pumpScreen(tester, today);
    expect(_isSelected(tester, today), isTrue);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();

    expect(_isSelected(tester, today), isFalse);
  });

  testWidgets('other weeks start on Monday and returning focuses today', (
    tester,
  ) async {
    final today = DateTime(2030, 10, 16);
    final nextMonday = DateTime(2030, 10, 21);

    await _pumpScreen(tester, today);

    await tester.tap(find.byTooltip('Sljedeći tjedan'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, nextMonday), isTrue);

    await tester.tap(find.byTooltip('Prethodni tjedan'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, today), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(today))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
  });
}

Future<void> _pumpScreen(WidgetTester tester, DateTime referenceDate) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loginControllerProvider.overrideWith(_FakeLoginController.new),
        classSessionsControllerProvider.overrideWith(
          () => _FakeClassSessionsController([
            _session(referenceDate.add(const Duration(hours: 10))),
          ]),
        ),
      ],
      child: localizedTestApp(
        home: ClassSessionsScreen(referenceDate: referenceDate),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

bool _isSelected(WidgetTester tester, DateTime date) {
  return tester
          .widget<Semantics>(find.byKey(_summaryKey(date)))
          .properties
          .selected ??
      false;
}

Key _sectionKey(DateTime date) => ValueKey(
  'class-sessions-day-section-${DateUtils.dateOnly(date).toIso8601String()}',
);

Key _summaryKey(DateTime date) => ValueKey(
  'class-sessions-day-summary-${DateUtils.dateOnly(date).toIso8601String()}',
);

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

class _FakeClassSessionsController extends ClassSessionsController {
  _FakeClassSessionsController(this.classSessions);

  final List<ClassSession> classSessions;

  @override
  ClassSessionsState build() => ClassSessionsLoaded(classSessions);
}

ClassSession _session(DateTime startsAt) => ClassSession(
  id: 1,
  classTypeId: 1,
  classTypeName: 'Pilates',
  trainerId: 2,
  trainerFirstName: 'Filip',
  trainerLastName: 'Šarić',
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(hours: 1)),
  capacity: 12,
  bookedCount: 3,
  status: 'scheduled',
  recurringScheduleId: null,
  recurringScheduleStatus: null,
);
