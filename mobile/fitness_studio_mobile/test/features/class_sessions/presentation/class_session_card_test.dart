import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/widgets/class_session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('uses a green tint without showing available spot count', (
    tester,
  ) async {
    await _pumpCard(tester, _session(bookedCount: 3));

    final card = tester.widget<Card>(
      find.byKey(const ValueKey('class-session-card-1')),
    );

    expect(card.color, Colors.green.shade700.withValues(alpha: 0.1));
    expect(find.text('9 mjesta'), findsNothing);
    expect(find.text('Popunjeno'), findsNothing);
    expect(
      find.bySemanticsLabel('Pilates, Rezervacija: Dostupna'),
      findsOneWidget,
    );
  });

  testWidgets('uses a red tint when booking is unavailable', (tester) async {
    await _pumpCard(tester, _session(bookedCount: 12));

    final context = tester.element(
      find.byKey(const ValueKey('class-session-card-1')),
    );
    final card = tester.widget<Card>(
      find.byKey(const ValueKey('class-session-card-1')),
    );

    expect(
      card.color,
      Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
    );
    expect(find.text('Popunjeno'), findsNothing);
    expect(
      find.bySemanticsLabel('Pilates, Rezervacija: Nije dostupna'),
      findsOneWidget,
    );
  });

  testWidgets('uses a red tint after the class start time', (tester) async {
    await _pumpCard(
      tester,
      _session(bookedCount: 3, startsAt: DateTime(2020, 10, 16, 10)),
    );

    expect(
      find.bySemanticsLabel('Pilates, Rezervacija: Nije dostupna'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpCard(WidgetTester tester, ClassSession classSession) =>
    tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(
          body: ClassSessionCard(classSession: classSession, onTap: () {}),
        ),
      ),
    );

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
