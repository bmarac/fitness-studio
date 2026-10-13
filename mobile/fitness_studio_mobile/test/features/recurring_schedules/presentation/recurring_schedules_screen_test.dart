import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/class_type_option.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/fixed_schedule_member.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/change_recurring_schedule_status.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_fixed_schedule_members.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/move_fixed_schedule_member.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/presentation/screens/recurring_schedules_screen.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/repositories/recurring_schedules_repository.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule_draft.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/schedule_form_data.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/trainer_option.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  setUp(() async {
    await serviceLocator.reset();
    final repository = _FakeRepository();
    serviceLocator
      ..registerSingleton<RecurringSchedulesRepository>(repository)
      ..registerSingleton<GetRecurringSchedules>(
        GetRecurringSchedules(repository),
      )
      ..registerSingleton<ChangeRecurringScheduleStatus>(
        ChangeRecurringScheduleStatus(repository),
      )
      ..registerSingleton<GetFixedScheduleMembers>(
        GetFixedScheduleMembers(repository),
      )
      ..registerSingleton<MoveFixedScheduleMember>(
        MoveFixedScheduleMember(repository),
      );
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('groups schedules by weekday and shows fixed occupancy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule-day-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-7')), findsOneWidget);
    expect(find.text('7/12 članova'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final earlier = tester.getTopLeft(
      find.byKey(const ValueKey('recurring-schedule-card-2')),
    );
    final later = tester.getTopLeft(
      find.byKey(const ValueKey('recurring-schedule-card-1')),
    );
    expect(earlier.dy, lessThan(later.dy));
  });

  testWidgets('colors available schedules green and full schedules red', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    final availableFinder = find.byKey(
      const ValueKey('recurring-schedule-card-1'),
    );
    final fullFinder = find.byKey(const ValueKey('recurring-schedule-card-5'));
    final errorColor = Theme.of(
      tester.element(fullFinder),
    ).colorScheme.error.withValues(alpha: 0.1);

    expect(
      tester.widget<Card>(availableFinder).color,
      Colors.green.shade700.withValues(alpha: 0.1),
    );
    expect(tester.widget<Card>(fullFinder).color, errorColor);
  });

  testWidgets('keeps one-line and two-line schedule cards the same height', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    final shortCard = tester.getSize(
      find.byKey(const ValueKey('recurring-schedule-card-1')),
    );
    final longCard = tester.getSize(
      find.byKey(const ValueKey('recurring-schedule-card-2')),
    );

    expect(longCard.height, shortCard.height);
  });

  testWidgets('opens fixed members and lifecycle actions from a card', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.more_vert), findsNothing);
    await tester.tap(find.byKey(const ValueKey('recurring-schedule-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('Članovi'), findsOneWidget);
    expect(find.text('Iva Ivić'), findsOneWidget);
    expect(find.text('Premjesti'), findsOneWidget);
    expect(find.text('Pauziraj'), findsOneWidget);
    expect(find.text('Završi'), findsOneWidget);
  });

  testWidgets('moves a fixed member after destination confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('recurring-schedule-card-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('move-fixed-member-91')));
    await tester.pumpAndSettle();

    expect(find.text('Odaberi novi raspored za Iva Ivić'), findsOneWidget);
    final sourceInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('recurring-schedule-card-1')),
        matching: find.byType(InkWell),
      ),
    );
    expect(sourceInkWell.onTap, isNull);

    await tester.tap(find.byKey(const ValueKey('recurring-schedule-card-2')));
    await tester.pumpAndSettle();

    expect(find.text('Premjesti člana?'), findsOneWidget);
    expect(
      find.textContaining(
        'Iva Ivić u Funkcionalni trening za početnike, ponedjeljak u 17:00',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Premjesti'));
    await tester.pumpAndSettle();

    final repository =
        serviceLocator<RecurringSchedulesRepository>() as _FakeRepository;
    expect(repository.movedAssignmentId, 91);
    expect(repository.movedTargetScheduleId, 2);
    expect(find.text('Član je premješten u novi raspored.'), findsOneWidget);
  });

  testWidgets('keeps weekday headers fixed while schedules scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository =
        serviceLocator<RecurringSchedulesRepository>() as _FakeRepository;
    for (var id = 10; id < 18; id++) {
      repository.schedules.add(
        _FakeRepository._schedule(
          id,
          'Trening $id',
          1,
          '${id.toString().padLeft(2, '0')}:00:00',
          'active',
          3,
        ),
      );
    }

    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('schedule-day-header-1'));
    final firstCard = find.byKey(const ValueKey('recurring-schedule-card-10'));
    final initialHeaderY = tester.getTopLeft(header).dy;
    final initialCardY = tester.getTopLeft(firstCard).dy;

    await tester.dragFrom(const Offset(100, 250), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(header).dy, initialHeaderY);
    expect(tester.getTopLeft(firstCard).dy, lessThan(initialCardY));
  });

  testWidgets('filters paused schedules', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(home: const RecurringSchedulesScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('Yoga'), findsNothing);

    final filterButton = find.byTooltip('Filtriraj rasporede');
    final addButton = find.byTooltip('Novi raspored');
    expect(
      tester.getCenter(filterButton).dx,
      lessThan(tester.getCenter(addButton).dx),
    );

    await tester.tap(filterButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pauzirani').last);
    await tester.pumpAndSettle();

    expect(find.text('Pilates'), findsNothing);
    expect(find.text('Yoga'), findsOneWidget);
  });

  testWidgets('trainer creates a schedule from the screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(const ['trainer'], trainerId: 8),
          ),
        ],
        child: localizedTestApp(home: const RecurringSchedulesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Novi raspored'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(fields.elementAt(1).onChanged, isNull);

    await tester.ensureVisible(find.text('Spremi raspored'));
    await tester.tap(find.text('Spremi raspored'));
    await tester.pumpAndSettle();

    expect(find.text('Novi raspored'), findsNothing);
    expect(
      find.byKey(const ValueKey('recurring-schedule-card-4')),
      findsOneWidget,
    );
  });

  testWidgets('admin can select the trainer in the create form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(const ['admin']),
          ),
        ],
        child: localizedTestApp(home: const RecurringSchedulesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Novi raspored'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<DropdownButtonFormField<int>>(
      find.byType(DropdownButtonFormField<int>),
    );
    expect(fields.elementAt(1).onChanged, isNotNull);
  });
}

class _FakeRepository implements RecurringSchedulesRepository {
  int? movedAssignmentId;
  int? movedTargetScheduleId;

  final schedules = <RecurringSchedule>[
    _schedule(1, 'Pilates', 1, '18:00:00', 'active', 7),
    _schedule(
      2,
      'Funkcionalni trening za početnike',
      1,
      '17:00:00',
      'active',
      4,
    ),
    _schedule(3, 'Yoga', 2, '19:00:00', 'paused', 6),
    _schedule(5, 'Mobility', 2, '20:00:00', 'active', 12),
  ];

  @override
  Future<Result<List<RecurringSchedule>>> getSchedules() async =>
      Success(schedules);

  @override
  Future<Result<List<FixedScheduleMember>>> getScheduleMembers(
    int scheduleId,
  ) async => const Success([
    FixedScheduleMember(assignmentId: 91, memberId: 21, memberName: 'Iva Ivić'),
  ]);

  @override
  Future<Result<void>> moveFixedScheduleMember({
    required int assignmentId,
    required int targetScheduleId,
  }) async {
    movedAssignmentId = assignmentId;
    movedTargetScheduleId = targetScheduleId;
    return const Success(null);
  }

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
        durationMinutes: draft.durationMinutes,
        capacity: draft.capacity,
        activeMemberCount: 0,
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

  static RecurringSchedule _schedule(
    int id,
    String name,
    int day,
    String time,
    String status,
    int activeMemberCount,
  ) => RecurringSchedule(
    id: id,
    classTypeName: name,
    trainerId: 8,
    trainerName: 'Ana Horvat',
    dayOfWeek: day,
    startsAtTime: time,
    durationMinutes: 60,
    capacity: 12,
    activeMemberCount: activeMemberCount,
    validFrom: DateTime(2026, 1, 1),
    validUntil: null,
    status: status,
    statusEffectiveFrom: status == 'active' ? null : DateTime(2026, 10, 1),
  );
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
