import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../../../navigation/app_routes.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/cancel_booking.dart';
import '../state/member_bookings_provider.dart';
import '../../../class_sessions/domain/entities/class_session.dart';
import '../../../class_sessions/presentation/state/my_class_sessions_provider.dart';
import '../../../recurring_schedules/domain/entities/trainer_option.dart';
import '../../../profile/presentation/state/profile_provider.dart';

class MyWorkoutsScreen extends ConsumerStatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  ConsumerState<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends ConsumerState<MyWorkoutsScreen> {
  WorkoutFilter _filter = WorkoutFilter.active;
  int? _selectedTrainerId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginControllerProvider);
    final isAdmin =
        authState is LoginSuccess && authState.session.user.hasRole('admin');
    final isTrainer =
        authState is LoginSuccess && authState.session.user.hasRole('trainer');
    final isMember = !isAdmin && !isTrainer;
    final selectedFilter = isMember
        ? ref.watch(memberBookingsProvider).filter
        : _filter;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.myWorkoutsTitle),
        actions: [
          PopupMenuButton<WorkoutFilter>(
            tooltip: context.l10n.filterWorkouts,
            initialValue: selectedFilter,
            onSelected: (value) {
              if (isMember) {
                ref.read(memberBookingsProvider.notifier).selectFilter(value);
              } else {
                setState(() => _filter = value);
              }
            },
            icon: Badge(
              isLabelVisible: selectedFilter != WorkoutFilter.active,
              child: const Icon(Icons.filter_list),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: WorkoutFilter.active,
                child: Text(context.l10n.filterActive),
              ),
              PopupMenuItem(
                value: WorkoutFilter.completed,
                child: Text(context.l10n.filterCompleted),
              ),
              PopupMenuItem(
                value: WorkoutFilter.cancelled,
                child: Text(context.l10n.filterCancelled),
              ),
              PopupMenuItem(
                value: WorkoutFilter.all,
                child: Text(context.l10n.filterAll),
              ),
            ],
          ),
        ],
      ),
      body: isAdmin
          ? _AdminWorkoutsView(
              classSessions: ref.watch(allClassSessionsProvider),
              trainers: ref.watch(trainerOptionsProvider),
              filter: _filter,
              selectedTrainerId: _selectedTrainerId,
              onTrainerSelected: (value) =>
                  setState(() => _selectedTrainerId = value),
            )
          : isTrainer
          ? _TrainerWorkoutsView(
              classSessions: ref.watch(myClassSessionsProvider),
              filter: _filter,
            )
          : const _MemberWorkoutsView(),
    );
  }
}

class _AdminWorkoutsView extends ConsumerWidget {
  const _AdminWorkoutsView({
    required this.classSessions,
    required this.trainers,
    required this.filter,
    required this.selectedTrainerId,
    required this.onTrainerSelected,
  });

  final AsyncValue<List<ClassSession>> classSessions;
  final AsyncValue<List<TrainerOption>> trainers;
  final WorkoutFilter filter;
  final int? selectedTrainerId;
  final ValueChanged<int?> onTrainerSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return trainers.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(message: localizedError(context, error)),
      data: (trainerItems) => classSessions.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(message: localizedError(context, error)),
        data: (sessionItems) {
          final visibleSessions = selectedTrainerId == null
              ? sessionItems
              : sessionItems
                    .where((item) => item.trainerId == selectedTrainerId)
                    .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedTrainerId,
                  decoration: InputDecoration(
                    labelText: context.l10n.labelTrainer,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(context.l10n.allTrainers),
                    ),
                    for (final trainer in trainerItems)
                      DropdownMenuItem<int?>(
                        value: trainer.id,
                        child: Text(trainer.fullName),
                      ),
                  ],
                  onChanged: onTrainerSelected,
                ),
              ),
              Expanded(
                child: _TrainerWorkoutsContent(
                  classSessions: visibleSessions,
                  filter: filter,
                  onRefresh: () async {
                    ref.invalidate(allClassSessionsProvider);
                    ref.invalidate(trainerOptionsProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberWorkoutsView extends ConsumerStatefulWidget {
  const _MemberWorkoutsView();

  @override
  ConsumerState<_MemberWorkoutsView> createState() =>
      _MemberWorkoutsViewState();
}

class _MemberWorkoutsViewState extends ConsumerState<_MemberWorkoutsView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreIfNeeded);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(memberBookingsProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memberBookingsProvider);
    final controller = ref.read(memberBookingsProvider.notifier);

    if (state.isInitialLoading) {
      return const LoadingView();
    }
    if (state.initialFailure case final failure?) {
      return ErrorView(
        message: localizedError(context, failure),
        onRetry: controller.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: state.items.isEmpty ? 1 : state.items.length + 1,
        itemBuilder: (context, index) {
          if (state.items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(child: Text(context.l10n.noReservedWorkouts)),
            );
          }
          if (index < state.items.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberWorkoutCard(booking: state.items[index]),
            );
          }
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.loadMoreFailure case final failure?) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    localizedError(context, failure),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: controller.retryLoadMore,
                    child: Text(context.l10n.actionRetry),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MemberWorkoutCard extends ConsumerStatefulWidget {
  const _MemberWorkoutCard({required this.booking});

  final Booking booking;

  @override
  ConsumerState<_MemberWorkoutCard> createState() => _MemberWorkoutCardState();
}

class _MemberWorkoutCardState extends ConsumerState<_MemberWorkoutCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final canCancel = booking.canMemberCancel(DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.formatDate(booking.classSessionStartsAt),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(context.formatTime(booking.classSessionStartsAt)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.classTypeName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(booking.trainerFullName),
                    ],
                  ),
                ),
                _BookingStatusBadge(status: booking.status),
              ],
            ),
            if (canCancel) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _confirmCancellation,
                  icon: _isCancelling
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_busy_outlined),
                  label: Text(
                    _isCancelling
                        ? context.l10n.cancellingSession
                        : context.l10n.cancelSessionAction,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    final booking = widget.booking;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.cancelSessionTitle),
        content: Text(
          context.l10n.cancelBookingDetails(
            booking.classTypeName,
            context.formatDate(booking.classSessionStartsAt),
            context.formatTime(booking.classSessionStartsAt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.cancelSessionAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    final result = await serviceLocator<CancelBooking>()(booking.id);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    switch (result) {
      case Success():
        await ref.read(memberBookingsProvider.notifier).refresh();
        ref.invalidate(profileProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.sessionCancelled)));
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'attended' => (context.l10n.bookingStatusAttended, Colors.green),
      'no_show' => (context.l10n.bookingStatusNoShow, Colors.red),
      'cancelled' => (context.l10n.bookingStatusCancelled, Colors.grey),
      'late_cancelled' => (
        context.l10n.bookingStatusLateCancelled,
        Colors.deepOrange,
      ),
      'waitlisted' => (context.l10n.bookingStatusWaitlisted, Colors.orange),
      _ => (context.l10n.bookingStatusBooked, Colors.blue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

class _TrainerWorkoutsView extends ConsumerWidget {
  const _TrainerWorkoutsView({
    required this.classSessions,
    required this.filter,
  });

  final AsyncValue<List<ClassSession>> classSessions;
  final WorkoutFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return classSessions.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorView(
        message: localizedError(context, error),
        onRetry: () => ref.invalidate(myClassSessionsProvider),
      ),
      data: (items) => _TrainerWorkoutsContent(
        classSessions: items,
        filter: filter,
        onRefresh: () async {
          ref.invalidate(myClassSessionsProvider);
        },
      ),
    );
  }
}

class _TrainerWorkoutsContent extends ConsumerWidget {
  const _TrainerWorkoutsContent({
    required this.classSessions,
    required this.filter,
    required this.onRefresh,
  });

  final List<ClassSession> classSessions;
  final WorkoutFilter filter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final visibleItems = _filterItems(classSessions, filter, now);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _WorkoutList(
            title: _filterLabel(context, filter),
            items: visibleItems,
          ),
        ],
      ),
    );
  }

  static List<ClassSession> _filterItems(
    List<ClassSession> items,
    WorkoutFilter filter,
    DateTime now,
  ) {
    final filtered = switch (filter) {
      WorkoutFilter.active => items.where(
        (item) => item.status == 'scheduled' && item.endsAt.isAfter(now),
      ),
      WorkoutFilter.completed => items.where(
        (item) =>
            item.status == 'completed' ||
            (item.status == 'scheduled' && !item.endsAt.isAfter(now)),
      ),
      WorkoutFilter.cancelled => items.where(
        (item) => item.status == 'cancelled',
      ),
      WorkoutFilter.all => items,
    };
    final result = filtered.toList();

    if (filter == WorkoutFilter.active) {
      result.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    } else {
      result.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    }

    return result;
  }

  static String _filterLabel(BuildContext context, WorkoutFilter filter) {
    return switch (filter) {
      WorkoutFilter.active => context.l10n.activeWorkouts,
      WorkoutFilter.completed => context.l10n.completedWorkouts,
      WorkoutFilter.cancelled => context.l10n.cancelledWorkouts,
      WorkoutFilter.all => context.l10n.allWorkouts,
    };
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
          Text(context.l10n.noSessions, style: theme.textTheme.bodyMedium)
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
                      context.formatTime(classSession.startsAt),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      context.formatWeekday(classSession.startsAt, short: true),
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
                      '${classSession.bookedCount}/${classSession.capacity}',
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
          'cancelled' => context.l10n.sessionStatusCancelled,
          'completed' => context.l10n.sessionStatusCompleted,
          _ when hasEnded => context.l10n.sessionStatusCompleted,
          _ => context.l10n.sessionStatusScheduled,
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
