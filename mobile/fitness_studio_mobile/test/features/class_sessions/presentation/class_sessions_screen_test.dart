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
    final yesterday = today.subtract(const Duration(days: 1));

    await _pumpScreen(tester, today);

    expect(_isSelected(tester, today), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(today))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
    expect(find.byKey(_sectionKey(yesterday)), findsOneWidget);
    expect(_isEnabled(tester, yesterday), isFalse);

    await tester.tap(find.byKey(_summaryKey(yesterday)));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, today), isTrue);
    expect(_isSelected(tester, yesterday), isFalse);
    expect(_weekButton(tester, 'Prethodni tjedan').onPressed, isNull);
  });

  testWidgets('can align Sunday to the top', (tester) async {
    final sunday = DateTime(2030, 10, 13);

    await _pumpScreen(tester, sunday);

    expect(_isSelected(tester, sunday), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(sunday))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
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
    expect(_weekButton(tester, 'Prethodni tjedan').onPressed, isNotNull);

    await tester.tap(find.byTooltip('Prethodni tjedan'));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, today), isTrue);
    expect(
      tester.getTopLeft(find.byKey(_sectionKey(today))).dy,
      closeTo(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 1),
    );
  });

  testWidgets('loads from now for this week and Monday for future weeks', (
    tester,
  ) async {
    final now = DateTime(2030, 10, 16, 12, 30);

    final controller = await _pumpScreen(tester, now);

    expect(controller.lastFrom, now.toUtc());
    expect(controller.lastTo, DateTime(2030, 10, 21).toUtc());

    await tester.tap(find.byTooltip('Sljedeći tjedan'));
    await tester.pumpAndSettle();

    expect(controller.lastFrom, DateTime(2030, 10, 21).toUtc());
    expect(controller.lastTo, DateTime(2030, 10, 28).toUtc());
  });
}

Future<_FakeClassSessionsController> _pumpScreen(
  WidgetTester tester,
  DateTime referenceDate,
) async {
  final controller = _FakeClassSessionsController([
    _session(referenceDate.add(const Duration(hours: 10))),
  ]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        loginControllerProvider.overrideWith(_FakeLoginController.new),
        classSessionsControllerProvider.overrideWith(() => controller),
      ],
      child: localizedTestApp(
        home: ClassSessionsScreen(referenceDate: referenceDate),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

bool _isSelected(WidgetTester tester, DateTime date) {
  return tester
          .widget<Semantics>(find.byKey(_summaryKey(date)))
          .properties
          .selected ??
      false;
}

bool _isEnabled(WidgetTester tester, DateTime date) {
  return tester
          .widget<Semantics>(find.byKey(_summaryKey(date)))
          .properties
          .enabled ??
      true;
}

Key _sectionKey(DateTime date) => ValueKey(
  'class-sessions-day-section-${DateUtils.dateOnly(date).toIso8601String()}',
);

Key _summaryKey(DateTime date) => ValueKey(
  'class-sessions-day-summary-${DateUtils.dateOnly(date).toIso8601String()}',
);

IconButton _weekButton(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
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
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  ClassSessionsState build() => ClassSessionsLoaded(classSessions);

  @override
  Future<void> loadClassSessions({DateTime? from, DateTime? to}) async {
    lastFrom = from;
    lastTo = to;
  }
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
