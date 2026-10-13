import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/class_type_option.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    final repository = _FakeRecurringSchedulesRepository();
    serviceLocator
      ..registerSingleton<RecurringSchedulesRepository>(repository)
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

  testWidgets('creates a trainer-owned schedule inside the sheet', (
    tester,
  ) async {
    var changed = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(const ['trainer'], trainerId: 7),
          ),
        ],
        child: localizedTestApp(
          home: Scaffold(
            body: RecurringSchedulesSheet(onChanged: () async => changed += 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Novi raspored'));
    await tester.pumpAndSettle();

    expect(find.text('Novi raspored'), findsOneWidget);
    expect(
      find.text('Termin će se ponavljati svaki tjedan od odabranog datuma.'),
      findsOneWidget,
    );
    final fields = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(fields.elementAt(1).onChanged, isNull);

    final saveButton = find.text('Spremi raspored');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(changed, 1);
    expect(find.text('Novi raspored'), findsNothing);
    expect(find.text('Strength'), findsOneWidget);
  });

  testWidgets('lets an admin select the schedule trainer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(const ['admin']),
          ),
        ],
        child: localizedTestApp(
          home: Scaffold(body: RecurringSchedulesSheet(onChanged: () async {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Novi raspored'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(fields.elementAt(1).onChanged, isNotNull);

    await tester.tap(find.text('Ana Horvat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filip Šarić').last);
    await tester.pumpAndSettle();

    expect(find.text('Filip Šarić'), findsOneWidget);
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
  Future<Result<void>> createSchedule(RecurringScheduleDraft draft) async {
    schedules.add(
      RecurringSchedule(
        id: 4,
        classTypeName: 'Strength',
        trainerId: draft.trainerId,
        trainerName: 'Ana Horvat',
        dayOfWeek: draft.dayOfWeek,
        startsAtTime: '18:00:00',
        validFrom: draft.validFrom,
        validUntil: null,
        status: 'active',
        statusEffectiveFrom: null,
      ),
    );
    return const Success(null);
  }

  @override
  Future<Result<ScheduleFormData>> getFormData() async => Success(
    ScheduleFormData(
      classTypes: const [
        ClassTypeOption(
          id: 11,
          name: 'Strength',
          defaultDurationMinutes: 60,
          defaultCapacity: 10,
        ),
      ],
      trainers: const [
        TrainerOption(
          id: 7,
          firstName: 'Ana',
          lastName: 'Horvat',
          status: 'active',
        ),
        TrainerOption(
          id: 8,
          firstName: 'Filip',
          lastName: 'Šarić',
          status: 'active',
        ),
      ],
    ),
  );

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

class _FakeLoginController extends LoginController {
  _FakeLoginController(this.roles, {this.trainerId});

  final List<String> roles;
  final int? trainerId;

  @override
  LoginState build() => LoginSuccess(
    AuthSession(
      accessToken: 'token',
      expiresAt: DateTime(2031),
      user: AuthenticatedUser(
        id: 1,
        studioId: 1,
        memberId: null,
        trainerId: trainerId,
        email: 'user@example.com',
        roles: roles,
      ),
    ),
  );
}
