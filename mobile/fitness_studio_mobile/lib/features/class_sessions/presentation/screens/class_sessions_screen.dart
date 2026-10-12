import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
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
import '../../../recurring_schedules/presentation/widgets/recurring_schedules_sheet.dart';

class ClassSessionsScreen extends ConsumerStatefulWidget {
  const ClassSessionsScreen({super.key});

  @override
  ConsumerState<ClassSessionsScreen> createState() =>
      _ClassSessionsScreenState();
}

class _ClassSessionsScreenState extends ConsumerState<ClassSessionsScreen> {
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
        title: Text(context.l10n.classSessionsTitle),
        actions: [
          if (canManageSchedules)
            IconButton(
              tooltip: context.l10n.schedulesTooltip,
              onPressed: _openSchedules,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
        ],
      ),
      body: switch (state) {
        ClassSessionsInitial() || ClassSessionsLoading() => const LoadingView(),
        ClassSessionsLoaded(classSessions: final classSessions) =>
          classSessions.isEmpty
              ? EmptyView(
                  title: context.l10n.noClassSessionsTitle,
                  message: context.l10n.noClassSessionsMessage,
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
        ClassSessionsError(failure: final failure) => ErrorView(
          message: failure.localized(context),
          onRetry: () => ref
              .read(classSessionsControllerProvider.notifier)
              .loadClassSessions(),
        ),
      },
      floatingActionButton: canManageSchedules
          ? FloatingActionButton(
              tooltip: context.l10n.newClassSessionTooltip,
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

  Future<void> _openSchedules() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (context) => RecurringSchedulesSheet(
        onChanged: () => ref
            .read(classSessionsControllerProvider.notifier)
            .loadClassSessions(),
      ),
    );
  }

  static DateTime _startOfWeek(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }
}

class _ClassSessionsByWeekdayView extends StatefulWidget {
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

  @override
  State<_ClassSessionsByWeekdayView> createState() =>
      _ClassSessionsByWeekdayViewState();
}

class _ClassSessionsByWeekdayViewState
    extends State<_ClassSessionsByWeekdayView> {
  final _scrollController = ScrollController();
  final _scrollViewportKey = GlobalKey();
  final _dayKeys = List.generate(7, (_) => GlobalKey());
  var _selectedDayIndex = 0;
  var _isScrollingToDay = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncSelectedDayWithScrollPosition);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncSelectedDayWithScrollPosition)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      7,
      (index) => widget.weekStart.add(Duration(days: index)),
    );
    final weekEnd = widget.weekStart.add(const Duration(days: 7));
    final sessionsByDay = <DateTime, List<ClassSession>>{
      for (final day in days) day: [],
    };

    for (final classSession in widget.classSessions) {
      final date = classSession.startsAt.toLocal();
      final day = DateTime(date.year, date.month, date.day);

      if (!day.isBefore(widget.weekStart) && day.isBefore(weekEnd)) {
        sessionsByDay[day]!.add(classSession);
      }
    }

    for (final sessions in sessionsByDay.values) {
      sessions.sort(
        (first, second) => first.startsAt.compareTo(second.startsAt),
      );
    }

    return Column(
      children: [
        _WeekHeader(
          weekStart: widget.weekStart,
          days: days,
          sessionsByDay: sessionsByDay,
          selectedDayIndex: _selectedDayIndex,
          onDaySelected: _scrollToDay,
          onPreviousWeek: widget.onPreviousWeek,
          onNextWeek: widget.onNextWeek,
        ),
        Expanded(
          key: _scrollViewportKey,
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                children: [
                  for (var index = 0; index < days.length; index++)
                    _DaySection(
                      key: _dayKeys[index],
                      title: context.formatWeekday(days[index]),
                      date: days[index],
                      sessions: sessionsByDay[days[index]]!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _syncSelectedDayWithScrollPosition() {
    if (_isScrollingToDay || !mounted) {
      return;
    }

    final viewportBox =
        _scrollViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize) {
      return;
    }

    final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
    var visibleDayIndex = _selectedDayIndex;

    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.extentAfter <= 1) {
      visibleDayIndex = _dayKeys.length - 1;
    } else {
      for (var index = 0; index < _dayKeys.length; index++) {
        final dayBox =
            _dayKeys[index].currentContext?.findRenderObject() as RenderBox?;
        if (dayBox == null || !dayBox.hasSize) {
          continue;
        }

        final dayTop = dayBox.localToGlobal(Offset.zero).dy;
        final dayBottom = dayTop + dayBox.size.height;
        if (dayTop <= viewportTop + 1 && dayBottom > viewportTop + 1) {
          visibleDayIndex = index;
          break;
        }

        if (dayTop > viewportTop) {
          visibleDayIndex = index;
          break;
        }
      }
    }

    if (visibleDayIndex != _selectedDayIndex) {
      setState(() {
        _selectedDayIndex = visibleDayIndex;
      });
    }
  }

  Future<void> _scrollToDay(int index) async {
    final dayContext = _dayKeys[index].currentContext;
    if (dayContext == null) {
      return;
    }

    setState(() {
      _selectedDayIndex = index;
      _isScrollingToDay = true;
    });

    await Scrollable.ensureVisible(
      dayContext,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );

    if (!mounted) {
      return;
    }

    _isScrollingToDay = false;
    _syncSelectedDayWithScrollPosition();
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.weekStart,
    required this.days,
    required this.sessionsByDay,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime weekStart;
  final List<DateTime> days;
  final Map<DateTime, List<ClassSession>> sessionsByDay;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;
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
                  tooltip: context.l10n.previousWeek,
                  onPressed: onPreviousWeek,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${context.formatShortDate(weekStart)} – ${context.formatShortDate(weekEnd)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.nextWeek,
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
                      label: context.formatWeekday(days[index], short: true),
                      date: days[index],
                      count: sessionsByDay[days[index]]!.length,
                      isSelected: index == selectedDayIndex,
                      onTap: () => onDaySelected(index),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.label,
    required this.date,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        selected: isSelected,
        button: true,
        label: context.l10n.daySessionsSemantics(
          label,
          context.formatShortDate(date),
          count,
        ),
        child: Material(
          color: isSelected ? theme.colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isToday && !isSelected
                ? BorderSide(color: theme.colorScheme.primary)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Column(
                children: [
                  Text(label, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : null,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    super.key,
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
                context.formatShortDate(date),
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
                context.l10n.noClassSessionsTitle,
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
