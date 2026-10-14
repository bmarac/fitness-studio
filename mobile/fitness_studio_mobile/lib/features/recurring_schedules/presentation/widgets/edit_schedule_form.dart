import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/recurring_schedule.dart';
import '../../domain/entities/trainer_option.dart';
import '../../domain/entities/update_recurring_schedule_draft.dart';
import '../../domain/usecases/get_trainers.dart';
import '../../domain/usecases/update_recurring_schedule.dart';

class EditScheduleForm extends StatefulWidget {
  const EditScheduleForm({
    super.key,
    required this.schedule,
    required this.onUpdated,
  });

  final RecurringSchedule schedule;
  final VoidCallback onUpdated;

  @override
  State<EditScheduleForm> createState() => _EditScheduleFormState();
}

class _EditScheduleFormState extends State<EditScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  List<TrainerOption>? _trainers;
  Failure? _failure;
  late int _trainerId;
  late int _dayOfWeek;
  late TimeOfDay _startsAtTime;
  late DateTime _effectiveFrom;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final parts = widget.schedule.startsAtTime.split(':');
    _trainerId = widget.schedule.trainerId;
    _dayOfWeek = widget.schedule.dayOfWeek;
    _startsAtTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    _capacityController.text = widget.schedule.capacity.toString();
    final today = DateUtils.dateOnly(DateTime.now());
    _effectiveFrom = widget.schedule.validFrom.isAfter(today)
        ? widget.schedule.validFrom
        : today;
    _loadTrainers();
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    final result = await serviceLocator<GetTrainers>()();
    if (!mounted) return;
    switch (result) {
      case Success(value: final trainers):
        setState(() => _trainers = trainers);
      case FailureResult(failure: final failure):
        setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trainers = _trainers;
    if (trainers == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: _failure == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_failure!.localized(context)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _failure = null);
                      _loadTrainers();
                    },
                    child: Text(context.l10n.actionRetry),
                  ),
                ],
              ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.editSchedule,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                key: const ValueKey('edit-schedule-trainer'),
                initialValue: _trainerId,
                decoration: InputDecoration(
                  labelText: context.l10n.labelTrainer,
                  border: const OutlineInputBorder(),
                ),
                items: trainers
                    .map(
                      (trainer) => DropdownMenuItem(
                        value: trainer.id,
                        child: Text(trainer.fullName),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _trainerId = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('edit-schedule-day'),
                initialValue: _dayOfWeek,
                decoration: InputDecoration(
                  labelText: context.l10n.dayLabel,
                  border: const OutlineInputBorder(),
                ),
                items: List.generate(7, (index) => index + 1)
                    .map(
                      (day) => DropdownMenuItem(
                        value: day,
                        child: Text(
                          context.formatWeekday(DateTime(2024, 1, day)),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _dayOfWeek = value!),
              ),
              const SizedBox(height: 16),
              _EditPickerField(
                key: const ValueKey('edit-schedule-time'),
                label: context.l10n.startTimeLabel,
                value: _startsAtTime.format(context),
                onTap: _isSubmitting ? null : _pickTime,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('edit-schedule-capacity'),
                controller: _capacityController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.labelCapacity,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  return number == null || number <= 0
                      ? context.l10n.positiveNumberRequired
                      : null;
                },
              ),
              const SizedBox(height: 16),
              _EditPickerField(
                key: const ValueKey('edit-schedule-effective-from'),
                label: context.l10n.effectiveFromLabel,
                value: context.formatDate(_effectiveFrom),
                onTap: _isSubmitting ? null : _pickDate,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const ValueKey('save-schedule-update'),
                onPressed: _isSubmitting ? null : _confirmAndSubmit,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(context.l10n.confirmScheduleUpdate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _startsAtTime,
    );
    if (value != null && mounted) {
      setState(() => _startsAtTime = value);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = widget.schedule.validFrom.isAfter(today)
        ? widget.schedule.validFrom
        : today;
    final value = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: firstDate,
      lastDate: widget.schedule.validUntil ?? DateTime(today.year + 5, 12, 31),
    );
    if (value != null && mounted) {
      setState(() => _effectiveFrom = value);
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final capacity = int.parse(_capacityController.text);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.editSchedule),
        content: Text(
          '${widget.schedule.trainerName} → ${_trainerName()}\n'
          '${context.formatWeekday(DateTime(2024, 1, widget.schedule.dayOfWeek))} '
          '${widget.schedule.startsAtTime.substring(0, 5)} → '
          '${context.formatWeekday(DateTime(2024, 1, _dayOfWeek))} '
          '${_startsAtTime.format(context)}\n'
          '${context.l10n.labelCapacity}: ${widget.schedule.capacity} → $capacity\n'
          '${context.l10n.effectiveFromLabel}: ${context.formatDate(_effectiveFrom)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.confirmScheduleUpdate),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final result = await serviceLocator<UpdateRecurringSchedule>()(
      widget.schedule.id,
      UpdateRecurringScheduleDraft(
        trainerId: _trainerId,
        dayOfWeek: _dayOfWeek,
        startsAtTime: DateTime(
          2000,
          1,
          1,
          _startsAtTime.hour,
          _startsAtTime.minute,
        ),
        capacity: capacity,
        effectiveFrom: _effectiveFrom,
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        widget.onUpdated();
      case FailureResult(failure: final failure):
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }

  String _trainerName() =>
      _trainers!.firstWhere((trainer) => trainer.id == _trainerId).fullName;
}

class _EditPickerField extends StatelessWidget {
  const _EditPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.expand_more),
        enabled: onTap != null,
      ),
      child: Text(value),
    ),
  );
}
