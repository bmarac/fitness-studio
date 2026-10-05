import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../auth/presentation/state/login_state.dart';
import '../../domain/entities/class_type_option.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/entities/schedule_form_data.dart';
import '../state/create_schedule_controller.dart';
import '../state/create_schedule_state.dart';

class CreateScheduleScreen extends ConsumerStatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  ConsumerState<CreateScheduleScreen> createState() =>
      _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends ConsumerState<CreateScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _initialized = false;
  int? _classTypeId;
  int? _trainerId;
  int _dayOfWeek = DateTime.now().weekday;
  TimeOfDay _startsAtTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _validFrom = DateUtils.dateOnly(DateTime.now());

  static const _weekdays = {
    1: 'Ponedjeljak',
    2: 'Utorak',
    3: 'Srijeda',
    4: 'Cetvrtak',
    5: 'Petak',
    6: 'Subota',
    7: 'Nedjelja',
  };

  @override
  void dispose() {
    _durationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createScheduleControllerProvider);

    ref.listen(createScheduleControllerProvider, (previous, next) {
      if (next is CreateScheduleSuccess) {
        Navigator.of(context).pop(true);
      }

      if (next case CreateScheduleReady(errorMessage: final message?)
          when previous is! CreateScheduleReady ||
              previous.errorMessage != message) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    if (state case CreateScheduleReady(formData: final formData)) {
      _initialize(formData);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Novi termin')),
      body: switch (state) {
        CreateScheduleLoading() => const LoadingView(),
        CreateScheduleLoadError(message: final message) => ErrorView(
          message: message,
          onRetry: () => ref
              .read(createScheduleControllerProvider.notifier)
              .loadFormData(),
        ),
        CreateScheduleReady(
          formData: final formData,
          isSubmitting: final isSubmitting,
        ) =>
          _buildForm(formData, isSubmitting),
        CreateScheduleSuccess() => const LoadingView(),
      },
    );
  }

  Widget _buildForm(ScheduleFormData formData, bool isSubmitting) {
    if (formData.classTypes.isEmpty || formData.trainers.isEmpty) {
      return const Center(child: Text('Nedostaju vrste treninga ili treneri.'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _classTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Vrsta treninga',
                      prefixIcon: Icon(Icons.fitness_center),
                      border: OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Trener',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: formData.trainers
                        .map(
                          (trainer) => DropdownMenuItem(
                            value: trainer.id,
                            child: Text(trainer.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: isSubmitting
                        ? null
                        : (value) => setState(() => _trainerId = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _dayOfWeek,
                    decoration: const InputDecoration(
                      labelText: 'Dan',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _weekdays.entries
                        .map(
                          (weekday) => DropdownMenuItem(
                            value: weekday.key,
                            child: Text(weekday.value),
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
                    label: 'Vrijeme početka',
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
                          decoration: const InputDecoration(
                            labelText: 'Trajanje (min)',
                            border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Kapacitet',
                            border: OutlineInputBorder(),
                          ),
                          validator: _positiveNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _PickerField(
                    icon: Icons.event_outlined,
                    label: 'Vrijedi od',
                    value: _formatDate(_validFrom),
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
                    label: Text(isSubmitting ? 'Spremam...' : 'Spremi termin'),
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
    final classType = formData.classTypes.first;

    _classTypeId = classType.id;
    _trainerId =
        formData.trainers.any((trainer) => trainer.id == currentTrainerId)
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

  static String? _positiveNumberValidator(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0 ? 'Unesi broj veći od 0.' : null;
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}.';
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
