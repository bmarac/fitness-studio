import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/localization.dart';
import '../features/auth/presentation/state/login_controller.dart';
import '../features/auth/presentation/state/login_state.dart';
import 'app_routes.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(loginControllerProvider);
    final isStaff =
        authState is LoginSuccess &&
        (authState.session.user.hasRole('trainer') ||
            authState.session.user.hasRole('admin'));

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go(
              isStaff ? AppRoutes.recurringSchedules : AppRoutes.classSessions,
            );
            return;
          }
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: isStaff
                ? context.l10n.navRecurringSchedules
                : context.l10n.navClassSessions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_available_outlined),
            selectedIcon: const Icon(Icons.event_available),
            label: context.l10n.navMyWorkouts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
