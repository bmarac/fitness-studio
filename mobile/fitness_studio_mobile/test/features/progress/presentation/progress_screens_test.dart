import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/member_progress.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/progress_management.dart';
import 'package:fitness_studio_mobile/features/progress/domain/repositories/progress_repository.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/screens/create_measurement_screen.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/screens/members_progress_screen.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/state/progress_management_providers.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  late _Repository repository;

  setUp(() async {
    await serviceLocator.reset();
    repository = _Repository();
    serviceLocator.registerSingleton<ProgressRepository>(repository);
  });
  tearDown(() => serviceLocator.reset());

  testWidgets('form shows active fields and accepts unrestricted decimals', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementParametersProvider.overrideWith(
            (ref) async => _parameters,
          ),
        ],
        child: localizedTestApp(
          home: const CreateMeasurementScreen(
            memberId: 7,
            memberName: 'Ana Horvat',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visina'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '20,1234');
    await tester.ensureVisible(find.text('Spremi mjerenje'));
    await tester.tap(find.text('Spremi mjerenje'));
    await tester.pumpAndSettle();

    expect(repository.created!.values.single.value, 20.1234);
  });

  testWidgets('valid form saves normalized values and note', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementParametersProvider.overrideWith(
            (ref) async => _parameters,
          ),
        ],
        child: localizedTestApp(
          home: const CreateMeasurementScreen(
            memberId: 7,
            memberName: 'Ana Horvat',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '172,5');
    await tester.enterText(fields.at(1), '22,8');
    await tester.enterText(fields.at(2), '  Kontrola  ');
    await tester.ensureVisible(find.text('Spremi mjerenje'));
    await tester.tap(find.text('Spremi mjerenje'));
    await tester.pumpAndSettle();

    expect(repository.memberId, 7);
    expect(repository.created!.note, 'Kontrola');
    expect(repository.created!.values, hasLength(2));
    expect(repository.created!.values.first.parameterId, 1);
    expect(repository.created!.values.first.value, 172.5);
    expect(repository.created!.values.last.parameterId, 2);
    expect(repository.created!.values.last.value, 22.8);
  });

  testWidgets('member list filters by name and email', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressMembersProvider.overrideWith(
            (ref) async => const [
              ProgressMember(
                id: 1,
                firstName: 'Ana',
                lastName: 'Horvat',
                email: 'ana@example.com',
                status: 'active',
              ),
              ProgressMember(
                id: 2,
                firstName: 'Ivan',
                lastName: 'Ivić',
                email: 'ivan@example.com',
                status: 'active',
              ),
            ],
          ),
        ],
        child: localizedTestApp(
          home: const MembersProgressScreen(canConfigureParameters: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Horvat'), findsOneWidget);
    expect(find.text('Ivan Ivić'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ana@example');
    await tester.pump();

    expect(find.text('Ana Horvat'), findsOneWidget);
    expect(find.text('Ivan Ivić'), findsNothing);
  });

  testWidgets('parameter settings icon is hidden without admin access', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressMembersProvider.overrideWith((ref) async => const []),
        ],
        child: localizedTestApp(
          home: const MembersProgressScreen(canConfigureParameters: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('measurement-parameters-settings')),
      findsNothing,
    );
  });

  testWidgets('settings icon opens simplified parameter editor and saves', (
    tester,
  ) async {
    await _pumpMembers(tester);

    await tester.tap(
      find.byKey(const ValueKey('measurement-parameters-settings')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parametri antropometrije'), findsOneWidget);
    expect(find.text('Naziv parametra'), findsNWidgets(2));
    expect(find.text('Jedinica'), findsNWidgets(2));
    expect(find.text('Kod parametra'), findsNothing);
    expect(find.text('Tip vrijednosti'), findsNothing);
    expect(find.text('Minimum'), findsNothing);
    expect(find.text('Broj decimala'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('parameter-name-0')),
      'Tjelesna visina',
    );
    await tester.tap(find.byKey(const ValueKey('parameter-active-1')));
    await tester.tap(find.byKey(const ValueKey('add-measurement-parameter')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('parameter-name-2')));
    await tester.enterText(
      find.byKey(const ValueKey('parameter-name-2')),
      'Opseg struka',
    );
    await tester.tap(find.byKey(const ValueKey('save-measurement-parameters')));
    await tester.pumpAndSettle();

    expect(repository.parameterSaves, 1);
    expect(repository.savedParameters.first.name, 'Tjelesna visina');
    expect(repository.savedParameters.first.code, 'height_cm');
    expect(repository.savedParameters[1].status, 'inactive');
    expect(repository.savedParameters.last.code, isEmpty);
    expect(repository.savedParameters.last.name, 'Opseg struka');
    expect(find.text('Konfiguracija je spremljena.'), findsOneWidget);
  });

  testWidgets('long press drag persists displayed parameter order', (
    tester,
  ) async {
    await _pumpMembers(tester);
    await tester.tap(
      find.byKey(const ValueKey('measurement-parameters-settings')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 2);
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-measurement-parameters')));
    await tester.pumpAndSettle();

    expect(repository.savedParameters.map((item) => item.code), [
      'bmi',
      'height_cm',
    ]);
    expect(repository.savedParameters.map((item) => item.sortOrder), [0, 1]);
  });

  testWidgets('member loading failure does not block parameter settings', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressMembersProvider.overrideWith(
            (ref) => Future<List<ProgressMember>>.error(Exception('members')),
          ),
        ],
        child: localizedTestApp(
          home: const MembersProgressScreen(canConfigureParameters: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('measurement-parameters-settings')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Naziv parametra'), findsNWidgets(2));
  });

  testWidgets('parameter loading failure stays inside settings modal', (
    tester,
  ) async {
    repository.failParameterLoad = true;
    await _pumpMembers(tester);
    await tester.tap(
      find.byKey(const ValueKey('measurement-parameters-settings')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nije moguće učitati parametre mjerenja.'),
      findsOneWidget,
    );
    expect(find.text('Pokušaj ponovno'), findsOneWidget);
  });

  testWidgets('closing a dirty parameter editor asks before discarding', (
    tester,
  ) async {
    await _pumpMembers(tester);
    await tester.tap(
      find.byKey(const ValueKey('measurement-parameters-settings')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('parameter-name-0')),
      'Promijenjeno',
    );

    await tester.tap(find.byTooltip('Zatvori'));
    await tester.pumpAndSettle();

    expect(find.text('Odbaciti promjene?'), findsOneWidget);
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();
    expect(find.text('Parametri antropometrije'), findsOneWidget);
  });
}

Future<void> _pumpMembers(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        progressMembersProvider.overrideWith((ref) async => const []),
      ],
      child: localizedTestApp(
        home: const MembersProgressScreen(canConfigureParameters: true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _parameters = [
  MeasurementParameter(
    id: 1,
    code: 'height_cm',
    name: 'Visina',
    unit: 'cm',
    sortOrder: 1,
    status: 'active',
  ),
  MeasurementParameter(
    id: 2,
    code: 'bmi',
    name: 'BMI',
    unit: null,
    sortOrder: 2,
    status: 'active',
  ),
];

class _Repository implements ProgressRepository {
  int? memberId;
  NewMeasurement? created;
  bool failParameterLoad = false;
  int parameterSaves = 0;
  List<MeasurementParameter> savedParameters = const [];

  @override
  Future<Result<void>> createMeasurement(
    int requestedMemberId,
    NewMeasurement measurement,
  ) async {
    memberId = requestedMemberId;
    created = measurement;
    return const Success(null);
  }

  @override
  Future<Result<MemberProgress>> getMemberProgress(int memberId) =>
      throw UnimplementedError();
  @override
  Future<Result<List<ProgressMember>>> getMembers() =>
      throw UnimplementedError();
  @override
  Future<Result<List<MeasurementParameter>>> getMeasurementParameters() =>
      Future.value(
        failParameterLoad
            ? const FailureResult(
                Failure(FailureKind.readMeasurementParameters),
              )
            : const Success(_parameters),
      );

  @override
  Future<Result<List<MeasurementParameter>>> saveMeasurementParameters(
    List<MeasurementParameter> parameters,
  ) async {
    parameterSaves += 1;
    savedParameters = parameters;
    return Success(parameters);
  }
}
