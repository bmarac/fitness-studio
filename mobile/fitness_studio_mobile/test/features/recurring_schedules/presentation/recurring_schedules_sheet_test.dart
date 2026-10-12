import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule_draft.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/schedule_form_data.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/trainer_option.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/repositories/recurring_schedules_repository.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/change_recurring_schedule_status.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/presentation/widgets/recurring_schedules_sheet.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    final repository = _FakeRecurringSchedulesRepository();
    serviceLocator
      ..registerSingleton<GetRecurringSchedules>(
        GetRecurringSchedules(repository),
      )
      ..registerSingleton<ChangeRecurringScheduleStatus>(
        ChangeRecurringScheduleStatus(repository),
      );
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('groups schedules and exposes lifecycle actions', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(body: RecurringSchedulesSheet(onChanged: () async {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AKTIVNI'), findsOneWidget);
    expect(find.text('PAUZIRANI'), findsOneWidget);
    expect(find.text('ZAVRŠENI'), findsOneWidget);
    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('Yoga'), findsOneWidget);
    expect(find.text('TRX'), findsOneWidget);

    await tester.tap(find.byTooltip('Upravljaj rasporedom').first);
    await tester.pumpAndSettle();

    expect(find.text('Pauziraj raspored'), findsOneWidget);
    expect(find.text('Završi raspored'), findsOneWidget);
  });
}

class _FakeRecurringSchedulesRepository
    implements RecurringSchedulesRepository {
  final schedules = [
    _schedule(id: 1, name: 'Pilates', status: 'active'),
    _schedule(id: 2, name: 'Yoga', status: 'paused'),
    _schedule(id: 3, name: 'TRX', status: 'ended'),
  ];

  @override
  Future<Result<List<RecurringSchedule>>> getSchedules() async =>
      Success(schedules);

  @override
  Future<Result<void>> changeScheduleStatus({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  }) async => const Success(null);

  @override
  Future<Result<void>> createSchedule(RecurringScheduleDraft draft) async =>
      const Success(null);

  @override
  Future<Result<ScheduleFormData>> getFormData() {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<TrainerOption>>> getTrainers() async => const Success([]);

  static RecurringSchedule _schedule({
    required int id,
    required String name,
    required String status,
  }) {
    return RecurringSchedule(
      id: id,
      classTypeName: name,
      trainerId: 7,
      trainerName: 'Ana Horvat',
      dayOfWeek: id,
      startsAtTime: '18:00:00',
      validFrom: DateTime(2026, 1, 1),
      validUntil: null,
      status: status,
      statusEffectiveFrom: status == 'active' ? null : DateTime(2026, 10, 9),
    );
  }
}
