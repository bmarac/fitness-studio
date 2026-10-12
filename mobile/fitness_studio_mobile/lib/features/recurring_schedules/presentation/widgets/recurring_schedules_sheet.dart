import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/recurring_schedule.dart';
import '../../domain/usecases/change_recurring_schedule_status.dart';
import '../../domain/usecases/get_recurring_schedules.dart';

enum RecurringScheduleAction { pause, resume, end }

extension RecurringScheduleActionValues on RecurringScheduleAction {
  String get endpoint => switch (this) {
    RecurringScheduleAction.pause => 'pause',
    RecurringScheduleAction.resume => 'resume',
    RecurringScheduleAction.end => 'end',
  };
}

class RecurringSchedulesSheet extends StatefulWidget {
  const RecurringSchedulesSheet({super.key, required this.onChanged});

  final Future<void> Function() onChanged;

  @override
  State<RecurringSchedulesSheet> createState() =>
      _RecurringSchedulesSheetState();
}

class _RecurringSchedulesSheetState extends State<RecurringSchedulesSheet> {
  List<RecurringSchedule>? _schedules;
  Failure? _failure;
  int? _changingScheduleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.86,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.schedulesTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.actionClose,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
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

    if (schedules!.isEmpty) {
      return Center(child: Text(context.l10n.noSchedules));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _ScheduleGroup(
          title: context.l10n.activeSchedules,
          schedules: schedules
              .where((item) => item.status == 'active')
              .toList(),
          changingScheduleId: _changingScheduleId,
          onAction: _changeStatus,
        ),
        _ScheduleGroup(
          title: context.l10n.pausedSchedules,
          schedules: schedules
              .where((item) => item.status == 'paused')
              .toList(),
          changingScheduleId: _changingScheduleId,
          onAction: _changeStatus,
        ),
        _ScheduleGroup(
          title: context.l10n.completedSchedules,
          schedules: schedules.where((item) => item.status == 'ended').toList(),
          changingScheduleId: _changingScheduleId,
          onAction: _changeStatus,
        ),
      ],
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
        await widget.onChanged();
        await _load();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

class _ScheduleGroup extends StatelessWidget {
  const _ScheduleGroup({
    required this.title,
    required this.schedules,
    required this.changingScheduleId,
    required this.onAction,
  });

  final String title;
  final List<RecurringSchedule> schedules;
  final int? changingScheduleId;
  final void Function(RecurringSchedule, RecurringScheduleAction) onAction;

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final schedule in schedules)
          Card(
            child: ListTile(
              title: Text(schedule.classTypeName),
              subtitle: Text(
                '${_weekday(context, schedule.dayOfWeek)}, ${_time(schedule.startsAtTime)} · ${schedule.trainerName}${_effectiveDate(context, schedule)}',
              ),
              trailing: changingScheduleId == schedule.id
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _ScheduleActions(schedule: schedule, onAction: onAction),
            ),
          ),
      ],
    );
  }

  static String _effectiveDate(
    BuildContext context,
    RecurringSchedule schedule,
  ) {
    final date = schedule.statusEffectiveFrom;
    if (date == null || schedule.status == 'active') return '';
    return ' · ${context.l10n.effectiveFromDate(context.formatDate(date))}';
  }

  static String _time(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  static String _weekday(BuildContext context, int value) =>
      context.formatWeekday(DateTime(2024, 1, value.clamp(1, 7)));
}

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({required this.schedule, required this.onAction});

  final RecurringSchedule schedule;
  final void Function(RecurringSchedule, RecurringScheduleAction) onAction;

  @override
  Widget build(BuildContext context) {
    if (schedule.status == 'ended') {
      return Tooltip(
        message: context.l10n.statusCompleted,
        child: const Icon(Icons.lock_outline),
      );
    }

    return PopupMenuButton<RecurringScheduleAction>(
      tooltip: context.l10n.manageSchedule,
      onSelected: (action) => onAction(schedule, action),
      itemBuilder: (context) => [
        if (schedule.status == 'active')
          PopupMenuItem(
            value: RecurringScheduleAction.pause,
            child: Text(context.l10n.pauseSchedule),
          ),
        if (schedule.status == 'paused')
          PopupMenuItem(
            value: RecurringScheduleAction.resume,
            child: Text(context.l10n.resumeSchedule),
          ),
        PopupMenuItem(
          value: RecurringScheduleAction.end,
          child: Text(context.l10n.finishSchedule),
        ),
      ],
    );
  }
}

Future<DateTime?> showRecurringScheduleChangeDialog(
  BuildContext context, {
  required RecurringScheduleAction action,
  required DateTime initialDate,
}) async {
  final today = DateUtils.dateOnly(DateTime.now());
  var selectedDate = DateUtils.dateOnly(
    initialDate.isBefore(today) ? today : initialDate,
  );

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(_actionTitle(context, action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_dialogMessage(context, action)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: today,
                  lastDate: DateTime(today.year + 5, 12, 31),
                );
                if (picked != null) {
                  setDialogState(() => selectedDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(context.formatDate(selectedDate)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(selectedDate),
            child: Text(_actionConfirmation(context, action)),
          ),
        ],
      ),
    ),
  );
}

String _actionTitle(BuildContext context, RecurringScheduleAction action) =>
    switch (action) {
      RecurringScheduleAction.pause => context.l10n.pauseSchedule,
      RecurringScheduleAction.resume => context.l10n.resumeSchedule,
      RecurringScheduleAction.end => context.l10n.finishSchedule,
    };

String _actionConfirmation(
  BuildContext context,
  RecurringScheduleAction action,
) => switch (action) {
  RecurringScheduleAction.pause => context.l10n.pauseAction,
  RecurringScheduleAction.resume => context.l10n.resumeAction,
  RecurringScheduleAction.end => context.l10n.finishAction,
};

String _dialogMessage(BuildContext context, RecurringScheduleAction action) =>
    switch (action) {
      RecurringScheduleAction.pause => context.l10n.pauseScheduleMessage,
      RecurringScheduleAction.resume => context.l10n.resumeScheduleMessage,
      RecurringScheduleAction.end => context.l10n.finishScheduleMessage,
    };

String _successMessage(BuildContext context, RecurringScheduleAction action) =>
    switch (action) {
      RecurringScheduleAction.pause => context.l10n.schedulePaused,
      RecurringScheduleAction.resume => context.l10n.scheduleResumed,
      RecurringScheduleAction.end => context.l10n.scheduleEnded,
    };
