import 'package:flutter/material.dart';

import '../../../../core/l10n/localization.dart';

enum RecurringScheduleAction { pause, resume, end }

extension RecurringScheduleActionValues on RecurringScheduleAction {
  String get endpoint => switch (this) {
    RecurringScheduleAction.pause => 'pause',
    RecurringScheduleAction.resume => 'resume',
    RecurringScheduleAction.end => 'end',
  };
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
