import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/entities/booking.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/screens/my_workouts_screen.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/state/member_bookings_provider.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/my_class_sessions_provider.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/trainer_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('member defaults to active bookings and can filter history', (
    tester,
  ) async {
    final future = _booking(
      id: 2,
      startsAt: DateTime(2030, 10, 12, 19),
      status: 'booked',
      classTypeName: 'Budući trening',
    );
    final past = _booking(
      id: 1,
      startsAt: DateTime(2020, 10, 5, 19),
      status: 'attended',
      classTypeName: 'Prošli trening',
    );
    final cancelled = _booking(
      id: 3,
      startsAt: DateTime(2021, 10, 7, 19),
      status: 'cancelled',
      classTypeName: 'Otkazani trening',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(['member']),
          ),
          memberBookingsProvider.overrideWith(
            () => _FakeMemberBookingsController({
              WorkoutFilter.active: [future],
              WorkoutFilter.completed: [past],
              WorkoutFilter.cancelled: [cancelled],
              WorkoutFilter.all: [future, cancelled, past],
            }),
          ),
        ],
        child: localizedTestApp(home: const MyWorkoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budući trening'), findsOneWidget);
    expect(find.text('Rezervirano'), findsOneWidget);
    expect(find.text('Prošli trening'), findsNothing);
    expect(find.text('Otkazani trening'), findsNothing);

    await tester.tap(find.byTooltip('Filtriraj treninge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Završeni').last);
    await tester.pumpAndSettle();

    expect(find.text('Prošli trening'), findsOneWidget);
    expect(find.text('Odrađeno'), findsOneWidget);
    expect(find.text('Budući trening'), findsNothing);

    await tester.tap(find.byTooltip('Filtriraj treninge'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktivni').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Otkaži termin'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Budući trening'), findsWidgets);
    expect(find.textContaining('Otkazuje se samo ovaj termin.'), findsNothing);
    expect(find.textContaining('Fiksna grupa ostaje aktivna.'), findsNothing);
  });

  testWidgets('member sees clear empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(['member']),
          ),
          memberBookingsProvider.overrideWith(
            () => _FakeMemberBookingsController(const {}),
          ),
        ],
        child: localizedTestApp(home: const MyWorkoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nema rezerviranih treninga.'), findsOneWidget);
  });

  testWidgets('trainer keeps assigned workout view', (tester) async {
    final session = _session(id: 1, trainerId: 7, classTypeName: 'Pilates');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(['trainer'], trainerId: 7),
          ),
          myClassSessionsProvider.overrideWith((ref) async => [session]),
        ],
        child: localizedTestApp(home: const MyWorkoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('Aktivni treninzi'), findsOneWidget);
    expect(find.text('4/10'), findsOneWidget);
    expect(find.text('4 polaznika / 10'), findsNothing);
    expect(find.text('Ovaj tjedan'), findsNothing);
    expect(find.text('treninga'), findsNothing);
    expect(find.text('prijava'), findsNothing);
    expect(find.text('sljedeći'), findsNothing);
  });

  testWidgets('admin defaults to all trainers and can filter one', (
    tester,
  ) async {
    final sessions = [
      _session(id: 1, trainerId: 7, classTypeName: 'Pilates'),
      _session(id: 2, trainerId: 8, classTypeName: 'TRX'),
    ];
    const trainers = [
      TrainerOption(
        id: 7,
        firstName: 'Kristina',
        lastName: 'Lisec',
        status: 'active',
      ),
      TrainerOption(
        id: 8,
        firstName: 'Filip',
        lastName: 'Šarić',
        status: 'active',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(
            () => _FakeLoginController(['admin']),
          ),
          allClassSessionsProvider.overrideWith((ref) async => sessions),
          trainerOptionsProvider.overrideWith((ref) async => trainers),
        ],
        child: localizedTestApp(home: const MyWorkoutsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Svi treneri'), findsOneWidget);
    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('TRX'), findsOneWidget);

    await tester.tap(find.text('Svi treneri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filip Šarić').last);
    await tester.pumpAndSettle();

    expect(find.text('Pilates'), findsNothing);
    expect(find.text('TRX'), findsOneWidget);
  });
}

class _FakeMemberBookingsController extends MemberBookingsController {
  _FakeMemberBookingsController(this.itemsByFilter);

  final Map<WorkoutFilter, List<Booking>> itemsByFilter;

  @override
  MemberBookingsState build() => MemberBookingsState(
    items: itemsByFilter[WorkoutFilter.active] ?? const [],
    isInitialLoading: false,
  );

  @override
  Future<void> selectFilter(WorkoutFilter filter) async {
    state = MemberBookingsState(
      filter: filter,
      items: itemsByFilter[filter] ?? const [],
      isInitialLoading: false,
    );
  }

  @override
  Future<void> refresh() async {}
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
        memberId: roles.contains('member') ? 10 : null,
        trainerId: trainerId,
        email: 'user@example.com',
        roles: roles,
      ),
    ),
  );
}

Booking _booking({
  required int id,
  required DateTime startsAt,
  required String status,
  required String classTypeName,
}) => Booking(
  id: id,
  memberId: 10,
  memberFirstName: 'Ana',
  memberLastName: 'Horvat',
  classSessionId: id + 50,
  bookingSource: 'fixed_schedule',
  memberFixedScheduleId: 4,
  classTypeId: 3,
  classTypeName: classTypeName,
  trainerId: 8,
  trainerFirstName: 'Filip',
  trainerLastName: 'Šarić',
  classSessionStartsAt: startsAt,
  classSessionEndsAt: startsAt.add(const Duration(hours: 1)),
  status: status,
  bookedAt: startsAt.subtract(const Duration(days: 14)),
  cancelledAt: status == 'cancelled'
      ? startsAt.subtract(const Duration(days: 1))
      : null,
  attendedAt: status == 'attended'
      ? startsAt.add(const Duration(hours: 1))
      : null,
);

ClassSession _session({
  required int id,
  required int trainerId,
  required String classTypeName,
}) => ClassSession(
  id: id,
  classTypeId: id,
  classTypeName: classTypeName,
  trainerId: trainerId,
  trainerFirstName: 'Trener',
  trainerLastName: '$trainerId',
  startsAt: DateTime(2030, 10, 12 + id, 18),
  endsAt: DateTime(2030, 10, 12 + id, 19),
  capacity: 10,
  bookedCount: 4,
  status: 'scheduled',
  recurringScheduleId: id,
  recurringScheduleStatus: 'active',
);
