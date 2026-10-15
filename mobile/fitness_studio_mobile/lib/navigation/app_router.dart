import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/localization.dart';
import '../features/auth/presentation/screens/auth_splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/studio_selection_screen.dart';
import '../features/auth/presentation/state/login_controller.dart';
import '../features/auth/presentation/state/login_state.dart';
import '../features/bookings/presentation/screens/my_workouts_screen.dart';
import '../features/class_sessions/presentation/screens/class_session_details_screen.dart';
import '../features/class_sessions/presentation/screens/class_sessions_screen.dart';
import '../features/class_types/presentation/screens/class_types_screen.dart';
import '../features/membership_plans/presentation/screens/membership_plans_screen.dart';
import '../features/member_packages/presentation/screens/member_packages_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/recurring_schedules/presentation/screens/recurring_schedules_screen.dart';
import '../features/payments/presentation/screens/payments_screen.dart';
import '../features/payments/presentation/screens/notifications_screen.dart';
import '../features/progress/presentation/screens/progress_screen.dart';
import '../features/progress/presentation/screens/members_progress_screen.dart';
import '../features/progress/presentation/screens/create_measurement_screen.dart';
import '../features/studio_settings/presentation/screens/studio_settings_screen.dart';
import '../features/trainers/presentation/screens/trainers_screen.dart';
import 'app_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref
    ..onDispose(refreshNotifier.dispose)
    ..listen(loginControllerProvider, (previous, next) {
      refreshNotifier.refresh();
    });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(loginControllerProvider);
      final location = state.matchedLocation;

      if (authState is LoginChecking) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      if (authState is LoginSuccess) {
        final isStaff =
            authState.session.user.hasRole('trainer') ||
            authState.session.user.hasRole('admin');
        if (location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.studioSelection ||
            location == AppRoutes.splash) {
          return AppRoutes.myWorkouts;
        }

        if (location == AppRoutes.classSessions && isStaff) {
          return AppRoutes.recurringSchedules;
        }
        if (location == AppRoutes.recurringSchedules && !isStaff) {
          return AppRoutes.classSessions;
        }
        if (location == AppRoutes.memberPackagesPath &&
            !authState.session.user.hasRole('admin')) {
          return AppRoutes.profile;
        }

        return null;
      }

      if (authState is LoginAccountReady) {
        return location == AppRoutes.studioSelection
            ? null
            : AppRoutes.studioSelection;
      }

      return location == AppRoutes.login || location == AppRoutes.register
          ? null
          : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const AuthSplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.studioSelection,
        builder: (context, state) => const StudioSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.classSessions,
                builder: (context, state) => const ClassSessionsScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.classSessionDetails,
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');

                      if (id == null) {
                        return const ClassSessionsScreen();
                      }

                      return ClassSessionDetailsScreen(classSessionId: id);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.recurringSchedules,
                builder: (context, state) => const RecurringSchedulesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myWorkouts,
                builder: (context, state) => const MyWorkoutsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.anthropometry,
                    builder: (context, state) => const ProgressScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.legacyProgress,
                    redirect: (context, state) => AppRoutes.anthropometryPath,
                  ),
                  GoRoute(
                    path: AppRoutes.membersProgress,
                    builder: (context, state) {
                      final authState = ref.read(loginControllerProvider);
                      final isAdmin =
                          authState is LoginSuccess &&
                          authState.session.user.roles.contains('admin');
                      return MembersProgressScreen(
                        canConfigureParameters: isAdmin,
                      );
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.memberAnthropometry,
                    builder: (context, state) {
                      final memberId = int.tryParse(
                        state.pathParameters['memberId'] ?? '',
                      );
                      if (memberId == null) return const ProfileScreen();
                      return ProgressScreen(
                        memberId: memberId,
                        memberName: state.extra as String?,
                      );
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.legacyMemberProgress,
                    redirect: (context, state) {
                      final memberId = int.tryParse(
                        state.pathParameters['memberId'] ?? '',
                      );
                      return memberId == null
                          ? AppRoutes.membersProgressPath
                          : AppRoutes.memberAnthropometryPath(memberId);
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.createMeasurement,
                    builder: (context, state) {
                      final memberId = int.tryParse(
                        state.pathParameters['memberId'] ?? '',
                      );
                      if (memberId == null) return const ProfileScreen();
                      return CreateMeasurementScreen(
                        memberId: memberId,
                        memberName:
                            state.extra as String? ?? context.l10n.roleMember,
                      );
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.payments,
                    builder: (context, state) => PaymentsScreen(
                      admin: state.uri.queryParameters['admin'] == 'true',
                    ),
                  ),
                  GoRoute(
                    path: AppRoutes.membershipPlans,
                    builder: (context, state) {
                      final authState = ref.read(loginControllerProvider);
                      final isAdmin =
                          authState is LoginSuccess &&
                          authState.session.user.roles.contains('admin');
                      return isAdmin
                          ? const MembershipPlansScreen()
                          : const ProfileScreen();
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.memberPackages,
                    builder: (context, state) {
                      final authState = ref.read(loginControllerProvider);
                      final isAdmin =
                          authState is LoginSuccess &&
                          authState.session.user.roles.contains('admin');
                      return isAdmin
                          ? const MemberPackagesScreen()
                          : const ProfileScreen();
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.notifications,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.trainers,
                    builder: (context, state) => const TrainersScreen(),
                    routes: [
                      GoRoute(
                        path: AppRoutes.createTrainer,
                        builder: (context, state) =>
                            const CreateTrainerScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: AppRoutes.classTypes,
                    builder: (context, state) {
                      final authState = ref.read(loginControllerProvider);
                      final isAdmin =
                          authState is LoginSuccess &&
                          authState.session.user.roles.contains('admin');
                      return isAdmin
                          ? const ClassTypesScreen()
                          : const ProfileScreen();
                    },
                  ),
                  GoRoute(
                    path: AppRoutes.studioSettings,
                    builder: (context, state) => const StudioSettingsScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.legacyOnboarding,
                    redirect: (context, state) => AppRoutes.trainersPath,
                  ),
                  GoRoute(
                    path: AppRoutes.legacyCreateMemberOnboarding,
                    redirect: (context, state) => AppRoutes.trainersPath,
                  ),
                  GoRoute(
                    path: AppRoutes.legacyCreateTrainerOnboarding,
                    redirect: (context, state) => AppRoutes.createTrainerPath,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}
