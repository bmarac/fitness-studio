import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../../class_sessions/domain/entities/class_session.dart';
import '../../../class_sessions/presentation/state/my_class_sessions_provider.dart';

enum _WorkoutFilter { active, completed, cancelled, all }

class MyWorkoutsScreen extends ConsumerStatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  ConsumerState<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends ConsumerState<MyWorkoutsScreen> {
  _WorkoutFilter _filter = _WorkoutFilter.active;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginControllerProvider);
    final isTrainer =
        authState is LoginSuccess && authState.session.user.hasRole('trainer');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji treninzi'),
        actions: [
          if (isTrainer)
            PopupMenuButton<_WorkoutFilter>(
              tooltip: 'Filtriraj treninge',
              initialValue: _filter,
              onSelected: (value) => setState(() => _filter = value),
              icon: Badge(
                isLabelVisible: _filter != _WorkoutFilter.active,
                child: const Icon(Icons.filter_list),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _WorkoutFilter.active,
                  child: Text('Aktivni'),
                ),
                PopupMenuItem(
                  value: _WorkoutFilter.completed,
                  child: Text('Završeni'),
                ),
                PopupMenuItem(
                  value: _WorkoutFilter.cancelled,
                  child: Text('Otkazani'),
                ),
                PopupMenuItem(value: _WorkoutFilter.all, child: Text('Svi')),
              ],
            ),
        ],
      ),
      body: isTrainer
          ? _TrainerWorkoutsView(
              classSessions: ref.watch(myClassSessionsProvider),
              filter: _filter,
            )
          : const Center(child: Text('Nema treninga za prikaz.')),
    );
  }
}

class _TrainerWorkoutsView extends ConsumerWidget {
  const _TrainerWorkoutsView({
    required this.classSessions,
    required this.filter,
  });

  final AsyncValue<List<ClassSession>> classSessions;
  final _WorkoutFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return classSessions.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(myClassSessionsProvider),
      ),
      data: (items) =>
          _TrainerWorkoutsContent(classSessions: items, filter: filter),
    );
  }
}

class _TrainerWorkoutsContent extends ConsumerWidget {
  const _TrainerWorkoutsContent({
    required this.classSessions,
    required this.filter,
  });

  final List<ClassSession> classSessions;
  final _WorkoutFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final visibleItems = _filterItems(classSessions, filter, now);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(myClassSessionsProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WeekSummary(classSessions: classSessions, now: now),
          const SizedBox(height: 24),
          _WorkoutList(title: _filterLabel(filter), items: visibleItems),
        ],
      ),
    );
  }

  static List<ClassSession> _filterItems(
    List<ClassSession> items,
    _WorkoutFilter filter,
    DateTime now,
  ) {
    final filtered = switch (filter) {
      _WorkoutFilter.active => items.where(
        (item) => item.status == 'scheduled' && item.endsAt.isAfter(now),
      ),
      _WorkoutFilter.completed => items.where(
        (item) =>
            item.status == 'completed' ||
            (item.status == 'scheduled' && !item.endsAt.isAfter(now)),
      ),
      _WorkoutFilter.cancelled => items.where(
        (item) => item.status == 'cancelled',
      ),
      _WorkoutFilter.all => items,
    };
    final result = filtered.toList();

    if (filter == _WorkoutFilter.active) {
      result.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    } else {
      result.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }

    return result;
  }

  static String _filterLabel(_WorkoutFilter filter) {
    return switch (filter) {
      _WorkoutFilter.active => 'Aktivni treninzi',
      _WorkoutFilter.completed => 'Završeni treninzi',
      _WorkoutFilter.cancelled => 'Otkazani treninzi',
      _WorkoutFilter.all => 'Svi treninzi',
    };
  }
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({required this.classSessions, required this.now});

  final List<ClassSession> classSessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startOfWeek = DateUtils.dateOnly(
      now.subtract(Duration(days: now.weekday - 1)),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final thisWeek = classSessions
        .where(
          (item) =>
              !item.startsAt.isBefore(startOfWeek) &&
              item.startsAt.isBefore(endOfWeek),
        )
        .toList();
    final upcoming = classSessions.where(
      (item) => item.startsAt.isAfter(now) && item.status == 'scheduled',
    );
    final next = upcoming.isEmpty ? null : upcoming.first;
    final participantCount = thisWeek.fold<int>(
      0,
      (sum, item) => sum + item.bookedCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ovaj tjedan',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryValue(
                value: '${thisWeek.length}',
                label: 'treninga',
              ),
            ),
            const SizedBox(height: 44, child: VerticalDivider()),
            Expanded(
              child: _SummaryValue(
                value: '$participantCount',
                label: 'prijava',
              ),
            ),
            const SizedBox(height: 44, child: VerticalDivider()),
            Expanded(
              child: _SummaryValue(
                value: next == null ? '-' : _formatShortDate(next.startsAt),
                label: 'sljedeći',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({required this.title, required this.items});

  final String title;
  final List<ClassSession> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text('Nema termina.', style: theme.textTheme.bodyMedium)
        else
          for (final item in items) ...[
            _TrainerWorkoutCard(classSession: item),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _TrainerWorkoutCard extends StatelessWidget {
  const _TrainerWorkoutCard({required this.classSession});

  final ClassSession classSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            context.push(AppRoutes.classSessionDetailsPath(classSession.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 54,
                child: Column(
                  children: [
                    Text(
                      _formatTime(classSession.startsAt),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _formatDay(classSession.startsAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classSession.classTypeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${classSession.bookedCount}/${classSession.capacity} polaznika',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(
                status: classSession.status,
                hasEnded: classSession.endsAt.isBefore(DateTime.now()),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.hasEnded});

  final String status;
  final bool hasEnded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = status == 'cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCancelled
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        switch (status) {
          'cancelled' => 'Otkazan',
          'completed' => 'Završen',
          _ when hasEnded => 'Završen',
          _ => 'Zakazan',
        },
        style: theme.textTheme.labelSmall?.copyWith(
          color: isCancelled
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDay(DateTime value) {
  const weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];
  return weekdays[value.weekday - 1];
}

String _formatShortDate(DateTime value) {
  return '${value.day}.${value.month}.';
}
