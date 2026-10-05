import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/auth_splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/state/login_controller.dart';
import '../features/auth/presentation/state/login_state.dart';
import '../features/bookings/presentation/screens/my_workouts_screen.dart';
import '../features/class_sessions/presentation/screens/class_session_details_screen.dart';
import '../features/class_sessions/presentation/screens/class_sessions_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/progress/presentation/screens/progress_screen.dart';
import '../features/progress/presentation/screens/members_progress_screen.dart';
import '../features/progress/presentation/screens/create_measurement_screen.dart';
import '../features/recurring_schedules/presentation/screens/create_schedule_screen.dart';
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
        if (location == AppRoutes.login || location == AppRoutes.splash) {
          return AppRoutes.classSessions;
        }

        return null;
      }

      return location == AppRoutes.login ? null : AppRoutes.login;
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
                    path: AppRoutes.createSchedule,
                    builder: (context, state) => const CreateScheduleScreen(),
                  ),
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
                    path: AppRoutes.progress,
                    builder: (context, state) => const ProgressScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.membersProgress,
                    builder: (context, state) => const MembersProgressScreen(),
                  ),
                  GoRoute(
                    path: AppRoutes.memberProgress,
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
                    path: AppRoutes.createMeasurement,
                    builder: (context, state) {
                      final memberId = int.tryParse(
                        state.pathParameters['memberId'] ?? '',
                      );
                      if (memberId == null) return const ProfileScreen();
                      return CreateMeasurementScreen(
                        memberId: memberId,
                        memberName: state.extra as String? ?? 'Član',
                      );
                    },
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
