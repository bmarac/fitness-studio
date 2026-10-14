import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../domain/entities/recurring_schedule.dart';
import '../../domain/entities/fixed_schedule_member.dart';
import '../../domain/entities/schedule_member_option.dart';
import '../../domain/usecases/add_fixed_schedule_member.dart';
import '../../domain/usecases/change_recurring_schedule_status.dart';
import '../../domain/usecases/get_fixed_schedule_members.dart';
import '../../domain/usecases/get_recurring_schedules.dart';
import '../../domain/usecases/get_schedule_member_options.dart';
import '../../domain/usecases/move_fixed_schedule_member.dart';
import '../widgets/create_schedule_form.dart';
import '../widgets/recurring_schedule_actions.dart';

class RecurringSchedulesScreen extends StatefulWidget {
  const RecurringSchedulesScreen({super.key});

  @override
  State<RecurringSchedulesScreen> createState() =>
      _RecurringSchedulesScreenState();
}

class _RecurringSchedulesScreenState extends State<RecurringSchedulesScreen> {
  List<RecurringSchedule>? _schedules;
  Failure? _failure;
  int? _changingScheduleId;
  String _status = 'active';
  bool _showCreateForm = false;
  _MoveSelection? _moveSelection;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _showCreateForm
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => setState(() => _showCreateForm = false),
                icon: const Icon(Icons.arrow_back),
              )
            : _moveSelection != null
            ? IconButton(
                tooltip: context.l10n.cancelMove,
                onPressed: () => setState(() => _moveSelection = null),
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _showCreateForm
              ? context.l10n.newScheduleTitle
              : _moveSelection != null
              ? context.l10n.selectMoveDestination(
                  _moveSelection!.member.memberName,
                )
              : context.l10n.schedulesTitle,
        ),
        actions: [
          if (!_showCreateForm && _moveSelection == null)
            PopupMenuButton<String>(
              tooltip: context.l10n.filterSchedules,
              initialValue: _status,
              onSelected: (status) => setState(() => _status = status),
              icon: Badge(
                isLabelVisible: _status != 'active',
                child: const Icon(Icons.filter_list),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'active',
                  child: Text(context.l10n.activeSchedules),
                ),
                PopupMenuItem(
                  value: 'paused',
                  child: Text(context.l10n.pausedSchedules),
                ),
                PopupMenuItem(
                  value: 'ended',
                  child: Text(context.l10n.completedSchedules),
                ),
              ],
            ),
          if (!_showCreateForm && _moveSelection == null)
            IconButton(
              tooltip: context.l10n.newScheduleTitle,
              onPressed: () => setState(() => _showCreateForm = true),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: _showCreateForm
          ? CreateScheduleForm(onCreated: _scheduleCreated)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final schedules = _schedules;
    if (schedules == null && _failure == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failure case final failure?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(failure.localized(context), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: Text(context.l10n.actionRetry),
              ),
            ],
          ),
        ),
      );
    }

    final visibleStatus = _moveSelection == null ? _status : 'active';
    final filtered =
        schedules!
            .where((schedule) => schedule.status == visibleStatus)
            .toList()
          ..sort((first, second) {
            final dayComparison = first.dayOfWeek.compareTo(second.dayOfWeek);
            return dayComparison != 0
                ? dayComparison
                : first.startsAtTime.compareTo(second.startsAtTime);
          });

    return _WeeklyScheduleGrid(
      schedules: filtered,
      changingScheduleId: _changingScheduleId,
      onRefresh: _load,
      moveSelection: _moveSelection,
      onScheduleTap: _handleScheduleTap,
    );
  }

  Future<void> _load() async {
    setState(() {
      _schedules = null;
      _failure = null;
    });

    final result = await serviceLocator<GetRecurringSchedules>()();
    if (!mounted) return;

    switch (result) {
      case Success(value: final schedules):
        setState(() => _schedules = schedules);
      case FailureResult(failure: final failure):
        setState(() => _failure = failure);
    }
  }

  Future<void> _scheduleCreated() async {
    if (!mounted) return;
    setState(() => _showCreateForm = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.scheduleCreated)));
    await _load();
  }

  Future<void> _changeStatus(
    RecurringSchedule schedule,
    RecurringScheduleAction action,
  ) async {
    final initialDate = schedule.statusEffectiveFrom ?? DateTime.now();
    final effectiveFrom = await showRecurringScheduleChangeDialog(
      context,
      action: action,
      initialDate: initialDate,
    );
    if (effectiveFrom == null || !mounted) return;

    setState(() => _changingScheduleId = schedule.id);
    final result = await serviceLocator<ChangeRecurringScheduleStatus>()(
      id: schedule.id,
      action: action.endpoint,
      effectiveFrom: effectiveFrom,
    );
    if (!mounted) return;

    setState(() => _changingScheduleId = null);
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessage(context, action))),
        );
        await _load();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }

  Future<void> _handleScheduleTap(RecurringSchedule schedule) async {
    final selection = _moveSelection;
    if (selection == null) {
      final addedMemberName = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => _ScheduleMembersSheet(
          schedule: schedule,
          onMove: (member) {
            Navigator.of(context).pop();
            setState(() {
              _status = 'active';
              _moveSelection = _MoveSelection(
                sourceSchedule: schedule,
                member: member,
              );
            });
          },
          onAction: (action) {
            Navigator.of(context).pop();
            _changeStatus(schedule, action);
          },
        ),
      );
      if (addedMemberName != null && mounted) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.fixedScheduleMemberAdded(addedMemberName),
            ),
          ),
        );
      }
      return;
    }

    if (!_canSelectDestination(schedule, selection)) return;
    await _confirmMove(schedule, selection);
  }

  bool _canSelectDestination(
    RecurringSchedule schedule,
    _MoveSelection selection,
  ) =>
      schedule.id != selection.sourceSchedule.id &&
      schedule.status == 'active' &&
      schedule.activeMemberCount < schedule.capacity;

  Future<void> _confirmMove(
    RecurringSchedule target,
    _MoveSelection selection,
  ) async {
    final weekday = context.formatWeekday(DateTime(2024, 1, target.dayOfWeek));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.moveMemberTitle),
        content: Text(
          context.l10n.moveMemberConfirmation(
            selection.member.memberName,
            target.classTypeName,
            weekday,
            _ScheduleCard.time(target.startsAtTime),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.confirmMove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _changingScheduleId = target.id);
    final result = await serviceLocator<MoveFixedScheduleMember>()(
      assignmentId: selection.member.assignmentId,
      targetScheduleId: target.id,
    );
    if (!mounted) return;

    setState(() => _changingScheduleId = null);
    switch (result) {
      case Success():
        setState(() => _moveSelection = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fixedScheduleMemberMoved)),
        );
        await _load();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

class _MoveSelection {
  const _MoveSelection({required this.sourceSchedule, required this.member});

  final RecurringSchedule sourceSchedule;
  final FixedScheduleMember member;
}

class _WeeklyScheduleGrid extends StatelessWidget {
  const _WeeklyScheduleGrid({
    required this.schedules,
    required this.changingScheduleId,
    required this.onRefresh,
    required this.moveSelection,
    required this.onScheduleTap,
  });

  static const _minimumColumnWidth = 168.0;

  final List<RecurringSchedule> schedules;
  final int? changingScheduleId;
  final Future<void> Function() onRefresh;
  final _MoveSelection? moveSelection;
  final ValueChanged<RecurringSchedule> onScheduleTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final columnWidth = availableWidth >= _minimumColumnWidth * 7
            ? availableWidth / 7
            : _minimumColumnWidth;
        final gridWidth = columnWidth * 7;

        return SingleChildScrollView(
          key: const ValueKey('recurring-schedules-grid'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: gridWidth + 32,
            height: constraints.maxHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var day = 1; day <= 7; day++)
                        SizedBox(
                          width: columnWidth,
                          child: _ScheduleDayHeader(day: day),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: onRefresh,
                      child: ListView(
                        key: const ValueKey('recurring-schedules-scroll'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var day = 1; day <= 7; day++)
                                SizedBox(
                                  width: columnWidth,
                                  child: _ScheduleDayColumn(
                                    day: day,
                                    schedules: schedules
                                        .where(
                                          (schedule) =>
                                              schedule.dayOfWeek == day,
                                        )
                                        .toList(),
                                    changingScheduleId: changingScheduleId,
                                    moveSelection: moveSelection,
                                    onScheduleTap: onScheduleTap,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleDayHeader extends StatelessWidget {
  const _ScheduleDayHeader({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        key: ValueKey('schedule-day-header-$day'),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          context
              .formatWeekday(DateTime(2024, 1, day), short: true)
              .toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ScheduleDayColumn extends StatelessWidget {
  const _ScheduleDayColumn({
    required this.day,
    required this.schedules,
    required this.changingScheduleId,
    required this.moveSelection,
    required this.onScheduleTap,
  });

  final int day;
  final List<RecurringSchedule> schedules;
  final int? changingScheduleId;
  final _MoveSelection? moveSelection;
  final ValueChanged<RecurringSchedule> onScheduleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: ValueKey('schedule-day-$day'),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            )
          else
            for (final schedule in schedules) ...[
              _ScheduleCard(
                schedule: schedule,
                isChanging: changingScheduleId == schedule.id,
                isEnabled:
                    moveSelection == null ||
                    (schedule.id != moveSelection!.sourceSchedule.id &&
                        schedule.activeMemberCount < schedule.capacity),
                onTap: () => onScheduleTap(schedule),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.isChanging,
    required this.isEnabled,
    required this.onTap,
  });

  final RecurringSchedule schedule;
  final bool isChanging;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final occupancy = schedule.capacity == 0
        ? 0.0
        : (schedule.activeMemberCount / schedule.capacity).clamp(0.0, 1.0);
    final hasAvailableSpots = schedule.activeMemberCount < schedule.capacity;
    final availabilityColor = hasAvailableSpots
        ? Colors.green.shade700
        : theme.colorScheme.error;

    return Opacity(
      opacity: isEnabled ? 1 : 0.45,
      child: Card(
        key: ValueKey('recurring-schedule-card-${schedule.id}'),
        color: availabilityColor.withValues(alpha: 0.1),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${time(schedule.startsAtTime)} · ${context.l10n.minutesShort(schedule.durationMinutes)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isChanging)
                      const SizedBox.square(
                        dimension: 32,
                        child: Center(
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      schedule.classTypeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  schedule.trainerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.scheduleFixedOccupancy(
                    schedule.activeMemberCount,
                    schedule.capacity,
                  ),
                  key: ValueKey('schedule-occupancy-${schedule.id}'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: occupancy,
                  color: availabilityColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String time(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}

class _ScheduleMembersSheet extends ConsumerStatefulWidget {
  const _ScheduleMembersSheet({
    required this.schedule,
    required this.onMove,
    required this.onAction,
  });

  final RecurringSchedule schedule;
  final ValueChanged<FixedScheduleMember> onMove;
  final ValueChanged<RecurringScheduleAction> onAction;

  @override
  ConsumerState<_ScheduleMembersSheet> createState() =>
      _ScheduleMembersSheetState();
}

class _ScheduleMembersSheetState extends ConsumerState<_ScheduleMembersSheet> {
  List<FixedScheduleMember>? _members;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _members = null;
      _failure = null;
    });
    final result = await serviceLocator<GetFixedScheduleMembers>()(
      widget.schedule.id,
    );
    if (!mounted) return;

    switch (result) {
      case Success(value: final members):
        setState(() => _members = members);
      case FailureResult(failure: final failure):
        setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final authState = ref.watch(loginControllerProvider);
    final isAdmin =
        authState is LoginSuccess && authState.session.user.hasRole('admin');

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.fixedScheduleMembers,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isAdmin &&
                      schedule.status == 'active' &&
                      schedule.activeMemberCount < schedule.capacity)
                    TextButton.icon(
                      key: const ValueKey('add-fixed-schedule-member'),
                      onPressed: _openAddMember,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: Text(context.l10n.addFixedScheduleMember),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(child: _buildMembers()),
              if (schedule.status != 'ended') ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (schedule.status == 'active')
                      OutlinedButton(
                        onPressed: () =>
                            widget.onAction(RecurringScheduleAction.pause),
                        child: Text(context.l10n.pauseAction),
                      ),
                    if (schedule.status == 'paused')
                      OutlinedButton(
                        onPressed: () =>
                            widget.onAction(RecurringScheduleAction.resume),
                        child: Text(context.l10n.resumeAction),
                      ),
                    FilledButton.tonal(
                      onPressed: () =>
                          widget.onAction(RecurringScheduleAction.end),
                      child: Text(context.l10n.finishAction),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddMember() async {
    final members = _members;
    if (members == null) return;

    final memberName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _AddFixedScheduleMemberSheet(
        schedule: widget.schedule,
        excludedMemberIds: members.map((member) => member.memberId).toSet(),
      ),
    );
    if (memberName == null || !mounted) return;

    Navigator.of(context).pop(memberName);
  }

  Widget _buildMembers() {
    if (_members == null && _failure == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_failure case final failure?) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(failure.localized(context), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ),
      );
    }

    final members = _members!;
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          context.l10n.noFixedScheduleMembers,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(member.memberName),
          trailing: TextButton.icon(
            key: ValueKey('move-fixed-member-${member.assignmentId}'),
            onPressed: () => widget.onMove(member),
            icon: const Icon(Icons.swap_horiz),
            label: Text(context.l10n.moveFixedScheduleMember),
          ),
        );
      },
    );
  }
}

class _AddFixedScheduleMemberSheet extends StatefulWidget {
  const _AddFixedScheduleMemberSheet({
    required this.schedule,
    required this.excludedMemberIds,
  });

  final RecurringSchedule schedule;
  final Set<int> excludedMemberIds;

  @override
  State<_AddFixedScheduleMemberSheet> createState() =>
      _AddFixedScheduleMemberSheetState();
}

class _AddFixedScheduleMemberSheetState
    extends State<_AddFixedScheduleMemberSheet> {
  List<ScheduleMemberOption>? _members;
  Failure? _failure;
  int? _selectedMemberId;
  String _query = '';
  bool _isSubmitting = false;
  late DateTime _startsOn;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _startsOn = today.isBefore(widget.schedule.validFrom)
        ? widget.schedule.validFrom
        : today;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _members = null;
      _failure = null;
    });
    final result = await serviceLocator<GetScheduleMemberOptions>()(
      widget.schedule.id,
      _startsOn,
    );
    if (!mounted) return;
    switch (result) {
      case Success(value: final members):
        setState(() => _members = members);
      case FailureResult(failure: final failure):
        setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height - bottomInset) * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.addFixedScheduleMember,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('fixed-schedule-member-search'),
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: context.l10n.searchMembers,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              key: const ValueKey('fixed-schedule-start-date'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(context.l10n.fixedScheduleStartsOn),
              subtitle: Text(context.formatDate(_startsOn)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _selectStartDate,
            ),
            const Divider(height: 1),
            Expanded(child: _buildMembers()),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('confirm-add-fixed-schedule-member'),
              onPressed: _selectedMemberId == null || _isSubmitting
                  ? null
                  : _submit,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.addFixedScheduleMemberAction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembers() {
    if (_members == null && _failure == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failure case final failure?) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(failure.localized(context), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loadMembers,
            child: Text(context.l10n.actionRetry),
          ),
        ],
      );
    }

    final query = _query.trim().toLowerCase();
    final available =
        _members!
            .where(
              (member) =>
                  member.status == 'active' &&
                  !widget.excludedMemberIds.contains(member.id),
            )
            .where(
              (member) =>
                  query.isEmpty ||
                  member.fullName.toLowerCase().contains(query) ||
                  member.email.toLowerCase().contains(query),
            )
            .toList(growable: false)
          ..sort((first, second) => first.fullName.compareTo(second.fullName));

    if (available.isEmpty) {
      return Center(child: Text(context.l10n.noMembersForFixedSchedule));
    }

    return RadioGroup<int>(
      groupValue: _selectedMemberId,
      onChanged: (value) {
        if (!_isSubmitting) setState(() => _selectedMemberId = value);
      },
      child: ListView.builder(
        itemCount: available.length,
        itemBuilder: (context, index) {
          final member = available[index];
          return RadioListTile<int>(
            key: ValueKey('fixed-schedule-member-${member.id}'),
            value: member.id,
            enabled: !_isSubmitting,
            title: Text(member.fullName),
            subtitle: Text(member.email),
          );
        },
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startsOn,
      firstDate: widget.schedule.validFrom,
      lastDate:
          widget.schedule.validUntil ??
          _startsOn.add(const Duration(days: 1825)),
    );
    if (selected != null && mounted) {
      setState(() {
        _startsOn = DateUtils.dateOnly(selected);
        _selectedMemberId = null;
      });
      await _loadMembers();
    }
  }

  Future<void> _submit() async {
    final memberId = _selectedMemberId;
    final members = _members;
    if (memberId == null || members == null) return;

    setState(() => _isSubmitting = true);
    final result = await serviceLocator<AddFixedScheduleMember>()(
      memberId: memberId,
      scheduleId: widget.schedule.id,
      startsOn: _startsOn,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    switch (result) {
      case Success():
        final member = members.singleWhere((item) => item.id == memberId);
        Navigator.of(context).pop(member.fullName);
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

String _successMessage(BuildContext context, RecurringScheduleAction action) =>
    switch (action) {
      RecurringScheduleAction.pause => context.l10n.schedulePaused,
      RecurringScheduleAction.resume => context.l10n.scheduleResumed,
      RecurringScheduleAction.end => context.l10n.scheduleEnded,
    };
