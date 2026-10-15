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
    final branchOrder = isStaff ? const [1, 0, 2] : const [0, 1, 2];
    final destinations = [
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
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: branchOrder.indexOf(navigationShell.currentIndex),
        onDestinationSelected: (index) {
          final branchIndex = branchOrder[index];
          if (branchIndex == 0) {
            context.go(
              isStaff ? AppRoutes.recurringSchedules : AppRoutes.classSessions,
            );
            return;
          }
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: isStaff
            ? [destinations[1], destinations[0], destinations[2]]
            : destinations,
      ),
    );
  }
}
