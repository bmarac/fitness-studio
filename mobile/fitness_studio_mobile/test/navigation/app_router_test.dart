import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/state/member_bookings_provider.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_controller.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_state.dart';
import 'package:fitness_studio_mobile/features/membership_plans/presentation/state/membership_plans_providers.dart';
import 'package:fitness_studio_mobile/features/profile/domain/entities/profile.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/state/profile_provider.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/member_progress.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/state/member_progress_provider.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/state/progress_management_providers.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/fixed_schedule_member.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/repositories/recurring_schedules_repository.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule_draft.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/schedule_form_data.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/trainer_option.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:fitness_studio_mobile/features/trainers/presentation/state/trainers_management_providers.dart';
import 'package:fitness_studio_mobile/navigation/app_router.dart';
import 'package:fitness_studio_mobile/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_test_app.dart';

void main() {
  tearDown(() => serviceLocator.reset());

  testWidgets('authenticated app starts on My Workouts tab', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInMemberController.new),
        memberBookingsProvider.overrideWith(_EmptyMemberBookingsController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.myWorkouts,
    );
    expect(find.text('Moji treninzi'), findsWidgets);
    expect(find.text('Termini'), findsOneWidget);
  });

  testWidgets('admin starts on the centered schedules tab', (tester) async {
    final repository = _EmptyRecurringSchedulesRepository();
    serviceLocator.registerSingleton<GetRecurringSchedules>(
      GetRecurringSchedules(repository),
    );
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInAdminController.new),
        memberBookingsProvider.overrideWith(_EmptyMemberBookingsController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.recurringSchedules,
    );
    expect(find.text('Rasporedi'), findsWidgets);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.selectedIndex, 1);
    expect(navigationBar.destinations[1], isA<NavigationDestination>());
    expect(
      (navigationBar.destinations[1] as NavigationDestination).label,
      'Rasporedi',
    );

    router.go(AppRoutes.classSessions);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.recurringSchedules,
    );
    expect(find.text('Rasporedi'), findsWidgets);
  });

  testWidgets('member schedules root redirects to termini', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInMemberController.new),
        memberBookingsProvider.overrideWith(_EmptyMemberBookingsController.new),
        classSessionsControllerProvider.overrideWith(
          _EmptyClassSessionsController.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.recurringSchedules);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.classSessions,
    );
    expect(find.text('Termini'), findsWidgets);
  });

  testWidgets('logged-out user can open registration', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedOutController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.registerPath);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pump();

    expect(router.routeInformationProvider.value.uri.path, AppRoutes.register);
    expect(find.text('Registracija'), findsOneWidget);
  });

  testWidgets('legacy onboarding route redirects to trainers', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInAdminController.new),
        managedTrainersProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('/profil/onboarding');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.trainersPath,
    );
    expect(find.text('Treneri'), findsOneWidget);
  });

  testWidgets('admin can open membership plans route', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInAdminController.new),
        membershipPlansProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.membershipPlansPath);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.membershipPlansPath,
    );
    expect(find.text('Paketi'), findsOneWidget);
    expect(find.text('Još nema paketa.'), findsOneWidget);
  });

  testWidgets('member can open anthropometry route', (tester) async {
    final container = _memberAnthropometryContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.anthropometryPath);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.anthropometryPath,
    );
    expect(find.text('Antropometrija'), findsOneWidget);
    expect(
      find.text('Još nema zabilježenih antropometrijskih mjerenja.'),
      findsOneWidget,
    );
    expect(find.text('Mjerenje'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Novo mjerenje'), findsOneWidget);
    expect(find.text('Ana Horvat'), findsOneWidget);
  });

  testWidgets('legacy personal progress route redirects to anthropometry', (
    tester,
  ) async {
    final container = _memberAnthropometryContainer();
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.legacyProgressPath);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.anthropometryPath,
    );
  });

  testWidgets('legacy member progress route redirects to anthropometry', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInAdminController.new),
        profileProvider.overrideWith((ref) async => _adminProfile),
        memberProgressProvider.overrideWith(
          (ref, memberId) async => _emptyProgress,
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.legacyMemberProgressPath(10));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.memberAnthropometryPath(10),
    );
  });
}

ProviderContainer _memberAnthropometryContainer() => ProviderContainer(
  overrides: [
    loginControllerProvider.overrideWith(_LoggedInMemberController.new),
    profileProvider.overrideWith((ref) async => _memberProfile),
    memberProgressProvider.overrideWith(
      (ref, memberId) async => _emptyProgress,
    ),
    measurementParametersProvider.overrideWith((ref) async => []),
  ],
);

const _emptyProgress = MemberProgress(latestValues: [], history: []);

const _memberProfile = Profile(
  user: ProfileUser(id: 4, email: 'ana@example.com', roles: ['member']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: ProfilePerson(
    id: 10,
    firstName: 'Ana',
    lastName: 'Horvat',
    email: 'ana@example.com',
    phone: null,
    status: 'active',
  ),
  trainer: null,
  membership: null,
  usage: null,
  fixedSchedules: [],
);

const _adminProfile = Profile(
  user: ProfileUser(id: 3, email: 'admin@example.com', roles: ['admin']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: null,
  trainer: null,
  membership: null,
  usage: null,
  fixedSchedules: [],
);

class _EmptyMemberBookingsController extends MemberBookingsController {
  @override
  MemberBookingsState build() =>
      const MemberBookingsState(isInitialLoading: false);
}

class _EmptyClassSessionsController extends ClassSessionsController {
  @override
  ClassSessionsState build() => const ClassSessionsLoaded([]);

  @override
  Future<void> loadClassSessions({DateTime? from, DateTime? to}) async {}
}

class _EmptyRecurringSchedulesRepository
    implements RecurringSchedulesRepository {
  @override
  Future<Result<List<RecurringSchedule>>> getSchedules() async =>
      const Success([]);

  @override
  Future<Result<List<FixedScheduleMember>>> getScheduleMembers(
    int scheduleId,
  ) async => const Success([]);

  @override
  Future<Result<void>> moveFixedScheduleMember({
    required int assignmentId,
    required int targetScheduleId,
  }) async => const Success(null);

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
  Future<Result<ScheduleFormData>> getFormData() async =>
      const Success(ScheduleFormData(classTypes: [], trainers: []));

  @override
  Future<Result<List<TrainerOption>>> getTrainers() async => const Success([]);
}

class _LoggedOutController extends LoginController {
  @override
  LoginState build() => const LoginInitial();
}

class _LoggedInMemberController extends LoginController {
  @override
  LoginState build() => LoginSuccess(
    AuthSession(
      accessToken: 'token',
      expiresAt: DateTime(2031),
      user: const AuthenticatedUser(
        id: 4,
        studioId: 1,
        memberId: 10,
        trainerId: null,
        email: 'ana.horvat@stayfitjoyful.demo',
        roles: ['member'],
      ),
    ),
  );
}

class _LoggedInAdminController extends LoginController {
  @override
  LoginState build() => LoginSuccess(
    AuthSession(
      accessToken: 'token',
      expiresAt: DateTime(2031),
      user: const AuthenticatedUser(
        id: 3,
        studioId: 1,
        memberId: null,
        trainerId: null,
        email: 'admin@example.com',
        roles: ['admin'],
      ),
    ),
  );
}
