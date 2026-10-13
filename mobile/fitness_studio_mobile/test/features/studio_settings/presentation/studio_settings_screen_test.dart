import 'package:fitness_studio_mobile/features/studio_settings/data/studio_settings_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/studio_settings/presentation/screens/studio_settings_screen.dart';
import 'package:fitness_studio_mobile/features/studio_settings/presentation/state/studio_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows every setting and exactly one save button', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeStudioSettingsDataSource());

    expect(find.text('Postavke studija'), findsOneWidget);
    expect(find.text('Pristup studiju'), findsOneWidget);
    expect(find.text('Postavke plaćanja'), findsOneWidget);
    expect(find.text('Primatelj'), findsOneWidget);
    expect(find.text('IBAN'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Podsjetnici'), findsOneWidget);
    expect(
      find.text('Podsjetnici članu (dani nakon dospijeća)'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('studio-settings-save')), findsOneWidget);
    expect(find.text('Spremi'), findsOneWidget);
  });

  testWidgets('toggle remains local until the single save action', (
    tester,
  ) async {
    final dataSource = _FakeStudioSettingsDataSource();
    await _pumpScreen(tester, dataSource);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(dataSource.updates, isEmpty);

    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('studio-settings-save'));
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(dataSource.updates, hasLength(1));
    expect(dataSource.updates.single.joinByCodeEnabled, isFalse);
    expect(dataSource.updates.single.joinCode, 'STAYFIT');
    expect(find.text('Postavke su spremljene.'), findsOneWidget);
  });

  testWidgets('failed save never shows a success message', (tester) async {
    final dataSource = _FakeStudioSettingsDataSource(failUpdate: true);
    await _pumpScreen(tester, dataSource);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('studio-settings-save'));

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(dataSource.updates, hasLength(1));
    expect(find.text('Postavke su spremljene.'), findsNothing);
    expect(find.textContaining('save failed'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  StudioSettingsRemoteDataSource dataSource,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [studioSettingsRemoteProvider.overrideWithValue(dataSource)],
      child: localizedTestApp(home: const StudioSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeStudioSettingsDataSource implements StudioSettingsRemoteDataSource {
  _FakeStudioSettingsDataSource({this.failUpdate = false});

  final bool failUpdate;
  final updates = <StudioConfiguration>[];

  @override
  Future<StudioConfiguration> getConfiguration() async => _configuration;

  @override
  Future<StudioConfiguration> updateConfiguration(
    StudioConfiguration configuration,
  ) async {
    updates.add(configuration);
    if (failUpdate) throw Exception('save failed');
    return configuration;
  }
}

const _configuration = StudioConfiguration(
  joinByCodeEnabled: true,
  joinCode: 'STAYFIT',
  recipientName: 'Stay Fit',
  iban: 'HR1210010051863000160',
  paymentModel: 'HR00',
  paymentReference: '123',
  paymentDescription: 'Članarina',
  memberReminderDays: [1, 3],
  adminReminderDays: [5],
  notificationTime: '09:00:00',
  isPaymentComplete: true,
);
