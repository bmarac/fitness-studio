import 'package:fitness_studio_mobile/core/error/result.dart';
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

  testWidgets('form shows only enterable fields and validates their range', (
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
    expect(find.text('BMI'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, '20');
    await tester.ensureVisible(find.text('Spremi mjerenje'));
    await tester.tap(find.text('Spremi mjerenje'));
    await tester.pump();

    expect(find.textContaining('Najmanja vrijednost'), findsOneWidget);
    expect(repository.created, isNull);
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
    await tester.enterText(fields.at(1), '  Kontrola  ');
    await tester.ensureVisible(find.text('Spremi mjerenje'));
    await tester.tap(find.text('Spremi mjerenje'));
    await tester.pumpAndSettle();

    expect(repository.memberId, 7);
    expect(repository.created!.note, 'Kontrola');
    expect(repository.created!.values.single.parameterId, 1);
    expect(repository.created!.values.single.value, 172.5);
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
        child: localizedTestApp(home: const MembersProgressScreen()),
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
}

const _parameters = [
  MeasurementParameter(
    id: 1,
    code: 'height_cm',
    name: 'Visina',
    unit: 'cm',
    source: 'manual',
    minValue: 50,
    maxValue: 250,
    decimalPlaces: 1,
    sortOrder: 1,
    status: 'active',
  ),
  MeasurementParameter(
    id: 2,
    code: 'bmi',
    name: 'BMI',
    unit: null,
    source: 'calculated',
    minValue: null,
    maxValue: null,
    decimalPlaces: 1,
    sortOrder: 2,
    status: 'active',
  ),
];

class _Repository implements ProgressRepository {
  int? memberId;
  NewMeasurement? created;

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
      throw UnimplementedError();
}
