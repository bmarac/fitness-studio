import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../domain/entities/class_type_option.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/entities/schedule_form_data.dart';
import '../state/create_schedule_controller.dart';
import '../state/create_schedule_state.dart';

class CreateScheduleForm extends ConsumerStatefulWidget {
  const CreateScheduleForm({super.key, required this.onCreated});

  final Future<void> Function() onCreated;

  @override
  ConsumerState<CreateScheduleForm> createState() => _CreateScheduleFormState();
}

class _CreateScheduleFormState extends ConsumerState<CreateScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _initialized = false;
  int? _classTypeId;
  int? _trainerId;
  int _dayOfWeek = DateTime.now().weekday;
  TimeOfDay _startsAtTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _validFrom = DateUtils.dateOnly(DateTime.now());

  @override
  void dispose() {
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createScheduleControllerProvider);

    ref.listen(createScheduleControllerProvider, (previous, next) async {
      if (next case CreateScheduleReady(
        failure: final failure?,
      ) when previous is! CreateScheduleReady || previous.failure != failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
      }

      if (next is CreateScheduleSuccess && previous is! CreateScheduleSuccess) {
        await widget.onCreated();
      }
    });

    if (state case CreateScheduleReady(formData: final formData)) {
      _initialize(formData);
    }

    return switch (state) {
      CreateScheduleLoading() => const LoadingView(),
      CreateScheduleLoadError(failure: final failure) => ErrorView(
        message: failure.localized(context),
        onRetry: () =>
            ref.read(createScheduleControllerProvider.notifier).loadFormData(),
      ),
      CreateScheduleReady(
        formData: final formData,
        isSubmitting: final isSubmitting,
      ) =>
        _buildForm(formData, isSubmitting),
      CreateScheduleSuccess() => const LoadingView(),
    };
  }

  Widget _buildForm(ScheduleFormData formData, bool isSubmitting) {
    if (formData.classTypes.isEmpty || formData.trainers.isEmpty) {
      return Center(child: Text(context.l10n.missingClassTypesOrTrainers));
    }

    final authState = ref.read(loginControllerProvider);
    final user = authState is LoginSuccess ? authState.session.user : null;
    final trainerOwnSchedule =
        user?.hasRole('trainer') == true && user?.hasRole('admin') != true;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.recurringScheduleDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    initialValue: _classTypeId,
                    decoration: InputDecoration(
                      labelText: context.l10n.classTypeLabel,
                      prefixIcon: const Icon(Icons.fitness_center),
                      border: const OutlineInputBorder(),
                    ),
                    items: formData.classTypes
                        .map(
                          (classType) => DropdownMenuItem(
                            value: classType.id,
                            child: Text(classType.name),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            final classType = formData.classTypes.firstWhere(
                              (item) => item.id == value,
                            );
                            setState(() {
                              _classTypeId = value;
                              _applyClassTypeDefaults(classType);
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _trainerId,
                    decoration: InputDecoration(
                      labelText: context.l10n.labelTrainer,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: const OutlineInputBorder(),
                    ),
                    items: formData.trainers
                        .map(
                          (trainer) => DropdownMenuItem(
                            value: trainer.id,
                            child: Text(trainer.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting || trainerOwnSchedule
                        ? null
                        : (value) => setState(() => _trainerId = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: InputDecoration(
                      labelText: context.l10n.dayLabel,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(7, (index) => index + 1)
                        .map(
                          (weekday) => DropdownMenuItem(
                            value: weekday,
                            child: Text(
                              context.formatWeekday(DateTime(2024, 1, weekday)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() => _dayOfWeek = value!),
                  ),
                  const SizedBox(height: 16),
                  _PickerField(
                    icon: Icons.schedule,
                    label: context.l10n.startTimeLabel,
                    value: _startsAtTime.format(context),
                    onTap: isSubmitting ? null : _pickTime,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.l10n.durationMinutesLabel,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _capacityController,
                          enabled: !isSubmitting,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: context.l10n.labelCapacity,
                            border: const OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PickerField(
                    icon: Icons.event_outlined,
                    label: context.l10n.validFromLabel,
                    value: context.formatDate(_validFrom),
                    onTap: isSubmitting ? null : _pickDate,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSubmitting
                          ? context.l10n.actionSaving
                          : context.l10n.saveSchedule,
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

  void _initialize(ScheduleFormData formData) {
    if (_initialized ||
        formData.classTypes.isEmpty ||
        formData.trainers.isEmpty) {
      return;
    }

    final authState = ref.read(loginControllerProvider);
    final currentTrainerId = authState is LoginSuccess
        ? authState.session.user.trainerId
        : null;
    final isTrainerOnly =
        authState is LoginSuccess &&
        authState.session.user.hasRole('trainer') &&
        !authState.session.user.hasRole('admin');
    final classType = formData.classTypes.first;

    _classTypeId = classType.id;
    _trainerId = isTrainerOnly
        ? currentTrainerId
        : formData.trainers.any((trainer) => trainer.id == currentTrainerId)
        ? currentTrainerId
        : formData.trainers.first.id;
    _applyClassTypeDefaults(classType);
    _initialized = true;
  }

  void _applyClassTypeDefaults(ClassTypeOption classType) {
    _durationController.text = classType.defaultDurationMinutes.toString();
    _capacityController.text = classType.defaultCapacity.toString();
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
    final value = await showDatePicker(
      context: context,
      initialDate: _validFrom,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (value != null && mounted) {
      setState(() => _validFrom = value);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate() ||
        _classTypeId == null ||
        _trainerId == null) {
      return;
    }

    final startsAtTime = DateTime(
      2000,
      1,
      1,
      _startsAtTime.hour,
      _startsAtTime.minute,
    );
    ref
        .read(createScheduleControllerProvider.notifier)
        .submit(
          RecurringScheduleDraft(
            classTypeId: _classTypeId!,
            trainerId: _trainerId!,
            dayOfWeek: _dayOfWeek,
            startsAtTime: startsAtTime,
            durationMinutes: int.parse(_durationController.text),
            capacity: int.parse(_capacityController.text),
            validFrom: _validFrom,
          ),
        );
  }

  String? _positiveNumberValidator(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0
        ? context.l10n.positiveNumberRequired
        : null;
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more),
          border: const OutlineInputBorder(),
          enabled: onTap != null,
        ),
        child: Text(value),
      ),
    );
  }
}
