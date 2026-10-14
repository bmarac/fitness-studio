import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/studio_settings/data/studio_settings_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/studio_settings/domain/configuration_items.dart';
import 'package:fitness_studio_mobile/features/studio_settings/domain/studio_configuration_repository.dart';
import 'package:fitness_studio_mobile/features/studio_settings/presentation/screens/studio_settings_screen.dart';
import 'package:fitness_studio_mobile/features/studio_settings/presentation/state/studio_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('shows five cards and no measurement settings or global save', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeStudioSettingsDataSource());

    expect(find.text('Postavke studija'), findsOneWidget);
    expect(find.text('Pristup studiju'), findsOneWidget);
    expect(find.text('Rezervacije'), findsOneWidget);
    expect(find.text('Postavke plaćanja'), findsOneWidget);
    expect(find.text('Podsjetnici'), findsOneWidget);
    expect(find.text('Vrste treninga'), findsOneWidget);
    expect(find.text('Parametri antropometrije'), findsNothing);
    expect(find.byKey(const ValueKey('studio-settings-save')), findsNothing);
  });

  testWidgets('configuration error does not hide independent cards', (
    tester,
  ) async {
    await _pumpScreen(tester, _FakeStudioSettingsDataSource(failGet: true));

    expect(find.text('Vrste treninga'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('class-types-settings-card')),
      findsOneWidget,
    );
  });

  testWidgets('access modal saves only after its save action', (tester) async {
    final dataSource = _FakeStudioSettingsDataSource();
    await _pumpScreen(tester, dataSource);

    await tester.tap(find.byKey(const ValueKey('studio-access-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(dataSource.updates, isEmpty);

    await tester.tap(find.byKey(const ValueKey('save-access-settings')));
    await tester.pumpAndSettle();

    expect(dataSource.updates, hasLength(1));
    expect(dataSource.updates.single.joinByCodeEnabled, isFalse);
    expect(find.text('Konfiguracija je spremljena.'), findsOneWidget);
  });

  testWidgets('failed modal save stays open and shows an error', (
    tester,
  ) async {
    final dataSource = _FakeStudioSettingsDataSource(failUpdate: true);
    await _pumpScreen(tester, dataSource);
    await tester.tap(find.byKey(const ValueKey('studio-access-card')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('save-access-settings')));
    await tester.pumpAndSettle();

    expect(dataSource.updates, hasLength(1));
    expect(find.text('Konfiguracija je spremljena.'), findsNothing);
    expect(find.textContaining('save failed'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-access-settings')), findsOneWidget);
  });

  testWidgets('booking modal validates cancellation cutoff', (tester) async {
    final dataSource = _FakeStudioSettingsDataSource();
    await _pumpScreen(tester, dataSource);
    await tester.tap(find.byKey(const ValueKey('booking-settings-card')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '169');
    await tester.tap(find.byKey(const ValueKey('save-booking-settings')));
    await tester.pump();

    expect(dataSource.updates, isEmpty);
    expect(find.text('Unesite cijeli broj od 0 do 168.'), findsOneWidget);
  });

  testWidgets('class types modal saves the edited collection once', (
    tester,
  ) async {
    final repository = _FakeConfigurationRepository();
    await _pumpScreen(
      tester,
      _FakeStudioSettingsDataSource(),
      repository: repository,
    );
    await tester.tap(find.byKey(const ValueKey('class-types-settings-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilates'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Power Pilates');
    await tester.tap(find.byKey(const ValueKey('save-class-types')));
    await tester.pumpAndSettle();

    expect(repository.classTypeSaves, 1);
    expect(repository.savedClassTypes.single.name, 'Power Pilates');
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  StudioSettingsRemoteDataSource dataSource, {
  _FakeConfigurationRepository? repository,
}) async {
  final configurationRepository = repository ?? _FakeConfigurationRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studioSettingsRemoteProvider.overrideWithValue(dataSource),
        studioConfigurationRepositoryProvider.overrideWithValue(
          configurationRepository,
        ),
        classTypeConfigurationsProvider.overrideWith(
          (ref) async => _classTypes,
        ),
      ],
      child: localizedTestApp(home: const StudioSettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeStudioSettingsDataSource implements StudioSettingsRemoteDataSource {
  _FakeStudioSettingsDataSource({
    this.failGet = false,
    this.failUpdate = false,
  });

  final bool failGet;
  final bool failUpdate;
  final updates = <StudioConfiguration>[];

  @override
  Future<StudioConfiguration> getConfiguration() async {
    if (failGet) throw Exception('load failed');
    return _configuration;
  }

  @override
  Future<StudioConfiguration> updateConfiguration(
    StudioConfiguration configuration,
  ) async {
    updates.add(configuration);
    if (failUpdate) throw Exception('save failed');
    return configuration;
  }
}

class _FakeConfigurationRepository implements StudioConfigurationRepository {
  int classTypeSaves = 0;
  List<ClassTypeConfiguration> savedClassTypes = const [];

  @override
  Future<Result<List<ClassTypeConfiguration>>> getClassTypes() async =>
      const Success(_classTypes);

  @override
  Future<Result<List<ClassTypeConfiguration>>> saveClassTypes(
    List<ClassTypeConfiguration> items,
    List<int> deletedIds,
  ) async {
    classTypeSaves += 1;
    savedClassTypes = items;
    return Success(items);
  }
}

const _classTypes = [
  ClassTypeConfiguration(
    id: 1,
    name: 'Pilates',
    defaultDurationMinutes: 60,
    defaultCapacity: 10,
    difficultyLevel: 'all_levels',
    status: 'active',
  ),
];

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
  cancellationCutoffHours: 12,
  isPaymentComplete: true,
);
