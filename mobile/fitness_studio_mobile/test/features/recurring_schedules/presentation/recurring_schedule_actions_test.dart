import 'package:fitness_studio_mobile/features/recurring_schedules/presentation/widgets/recurring_schedule_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  test('actions map to their API endpoints', () {
    expect(RecurringScheduleAction.pause.endpoint, 'pause');
    expect(RecurringScheduleAction.resume.endpoint, 'resume');
    expect(RecurringScheduleAction.end.endpoint, 'end');
  });

  for (final testCase
      in <
        ({
          RecurringScheduleAction action,
          String title,
          String message,
          String confirmation,
        })
      >[
        (
          action: RecurringScheduleAction.pause,
          title: 'Pauziraj raspored',
          message:
              'Od odabranog datuma otkazat će se ovaj i svi budući termini '
              'rasporeda. Raspored se kasnije može nastaviti.',
          confirmation: 'Pauziraj',
        ),
        (
          action: RecurringScheduleAction.resume,
          title: 'Nastavi raspored',
          message:
              'Od odabranog datuma ponovno će se kreirati termini i rezervacije '
              'aktivnih fiksnih članova.',
          confirmation: 'Nastavi',
        ),
        (
          action: RecurringScheduleAction.end,
          title: 'Završi raspored',
          message:
              'Od odabranog datuma raspored i povezane fiksne dodjele trajno '
              'završavaju. Ovu radnju nije moguće poništiti.',
          confirmation: 'Završi',
        ),
      ]) {
    testWidgets('confirms the ${testCase.action.name} action', (tester) async {
      final selectedDate = DateTime(2030, 1, 2);
      DateTime? result;

      await tester.pumpWidget(
        localizedTestApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showRecurringScheduleChangeDialog(
                  context,
                  action: testCase.action,
                  initialDate: selectedDate,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(testCase.title), findsOneWidget);
      expect(find.text(testCase.message), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, testCase.confirmation),
      );
      await tester.pumpAndSettle();

      expect(result, selectedDate);
    });
  }

  testWidgets('cancel closes the action dialog without a date', (tester) async {
    DateTime? result = DateTime(2030, 1, 2);

    await tester.pumpWidget(
      localizedTestApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showRecurringScheduleChangeDialog(
                context,
                action: RecurringScheduleAction.pause,
                initialDate: DateTime(2000),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
