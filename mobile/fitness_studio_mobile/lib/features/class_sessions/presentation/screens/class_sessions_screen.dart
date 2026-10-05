import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../../../navigation/app_routes.dart';
import '../../domain/entities/class_session.dart';
import '../state/class_sessions_controller.dart';
import '../state/class_sessions_state.dart';
import '../widgets/class_session_card.dart';

class ClassSessionsScreen extends ConsumerStatefulWidget {
  const ClassSessionsScreen({super.key});

  @override
  ConsumerState<ClassSessionsScreen> createState() =>
      _ClassSessionsScreenState();
}

class _ClassSessionsScreenState extends ConsumerState<ClassSessionsScreen> {
  bool _isLoggingOut = false;
  late DateTime _weekStart = _startOfWeek(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classSessionsControllerProvider);
    final authState = ref.watch(loginControllerProvider);
    final canManageSchedules =
        authState is LoginSuccess &&
        (authState.session.user.hasRole('trainer') ||
            authState.session.user.hasRole('admin'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Termini'),
        actions: [
          IconButton(
            tooltip: 'Odjavi se',
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: switch (state) {
        ClassSessionsInitial() || ClassSessionsLoading() => const LoadingView(),
        ClassSessionsLoaded(classSessions: final classSessions) =>
          classSessions.isEmpty
              ? const EmptyView(
                  title: 'Nema termina',
                  message: 'Trenutno nema raspisanih grupnih treninga.',
                )
              : _ClassSessionsByWeekdayView(
                  key: ValueKey(_weekStart),
                  classSessions: classSessions,
                  weekStart: _weekStart,
                  onPreviousWeek: () {
                    setState(() {
                      _weekStart = _weekStart.subtract(const Duration(days: 7));
                    });
                  },
                  onNextWeek: () {
                    setState(() {
                      _weekStart = _weekStart.add(const Duration(days: 7));
                    });
                  },
                  onRefresh: () => ref
                      .read(classSessionsControllerProvider.notifier)
                      .loadClassSessions(),
                ),
        ClassSessionsError(message: final message) => ErrorView(
          message: message,
          onRetry: () => ref
              .read(classSessionsControllerProvider.notifier)
              .loadClassSessions(),
        ),
      },
      floatingActionButton: canManageSchedules
          ? FloatingActionButton(
              tooltip: 'Novi termin',
              onPressed: _openCreateSchedule,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _openCreateSchedule() async {
    final created = await context.push<bool>(AppRoutes.createSchedulePath);

    if (created == true) {
      await ref
          .read(classSessionsControllerProvider.notifier)
          .loadClassSessions();
    }
  }

  static DateTime _startOfWeek(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Zelis li se odjaviti iz aplikacije?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    final error = await ref.read(loginControllerProvider.notifier).logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoggingOut = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _ClassSessionsByWeekdayView extends StatelessWidget {
  const _ClassSessionsByWeekdayView({
    super.key,
    required this.classSessions,
    required this.weekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onRefresh,
  });

  final List<ClassSession> classSessions;
  final DateTime weekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final Future<void> Function() onRefresh;

  static const _shortWeekdays = [
    'Pon',
    'Uto',
    'Sri',
    'Cet',
    'Pet',
    'Sub',
    'Ned',
  ];

  static const _longWeekdays = [
    'Ponedjeljak',
    'Utorak',
    'Srijeda',
    'Cetvrtak',
    'Petak',
    'Subota',
    'Nedjelja',
  ];

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));
    final sessionsByDay = <DateTime, List<ClassSession>>{
      for (final day in days) day: [],
    };

    for (final classSession in classSessions) {
      final date = classSession.startsAt.toLocal();
      final day = DateTime(date.year, date.month, date.day);

      if (!day.isBefore(weekStart) && day.isBefore(weekEnd)) {
        sessionsByDay[day]!.add(classSession);
      }
    }

    for (final sessions in sessionsByDay.values) {
      sessions.sort(
        (first, second) => first.startsAt.compareTo(second.startsAt),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _WeekHeader(
              weekStart: weekStart,
              days: days,
              sessionsByDay: sessionsByDay,
              onPreviousWeek: onPreviousWeek,
              onNextWeek: onNextWeek,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.builder(
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final sessions = sessionsByDay[day]!;

                return _DaySection(
                  title: _longWeekdays[index],
                  date: day,
                  sessions: sessions,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.days,
    required this.sessionsByDay,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime weekStart;
  final List<DateTime> days;
  final Map<DateTime, List<ClassSession>> sessionsByDay;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekEnd = days.last;

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Prethodni tjedan',
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _formatWeekRange(weekStart, weekEnd),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sljedeci tjedan',
                  onPressed: onNextWeek,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var index = 0; index < days.length; index++)
                  Expanded(
                    child: _DaySummary(
                      label: _ClassSessionsByWeekdayView._shortWeekdays[index],
                      date: days[index],
                      count: sessionsByDay[days[index]]!.length,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWeekRange(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return '${start.day}. - ${end.day}.${end.month}.${end.year}.';
    }

    return '${start.day}.${start.month}. - ${end.day}.${end.month}.${end.year}.';
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.label,
    required this.date,
    required this.count,
  });

  final String label;
  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isToday ? theme.colorScheme.onPrimaryContainer : null,
            ),
          ),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: count == 0
                  ? theme.colorScheme.outline
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.title,
    required this.date,
    required this.sessions,
  });

  final String title;
  final DateTime date;
  final List<ClassSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${date.day}.${date.month}.',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nema termina',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            for (var index = 0; index < sessions.length; index++) ...[
              ClassSessionCard(
                classSession: sessions[index],
                onTap: () => context.push(
                  AppRoutes.classSessionDetailsPath(sessions[index].id),
                ),
              ),
              if (index < sessions.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
