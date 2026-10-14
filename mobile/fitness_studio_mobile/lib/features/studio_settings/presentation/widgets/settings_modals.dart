import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../data/studio_settings_remote_data_source.dart';
import '../../domain/configuration_items.dart';
import '../state/studio_settings_provider.dart';

enum StudioSettingsSection { access, booking, payment, reminders }

Future<bool> showGeneralSettingsModal(
  BuildContext context,
  WidgetRef ref,
  StudioSettingsSection section,
  StudioConfiguration configuration,
) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _GeneralSettingsModal(
        section: section,
        configuration: configuration,
        dataSource: ref.read(studioSettingsRemoteProvider),
      ),
    ) ??
    false;

class _GeneralSettingsModal extends StatefulWidget {
  const _GeneralSettingsModal({
    required this.section,
    required this.configuration,
    required this.dataSource,
  });

  final StudioSettingsSection section;
  final StudioConfiguration configuration;
  final StudioSettingsRemoteDataSource dataSource;

  @override
  State<_GeneralSettingsModal> createState() => _GeneralSettingsModalState();
}

class _GeneralSettingsModalState extends State<_GeneralSettingsModal> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  bool _joinEnabled = false;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.configuration;
    _joinEnabled = c.joinByCodeEnabled;
    _controllers = [
      TextEditingController(text: c.joinCode ?? ''),
      TextEditingController(text: c.cancellationCutoffHours.toString()),
      TextEditingController(text: c.recipientName),
      TextEditingController(text: c.iban),
      TextEditingController(text: c.paymentModel),
      TextEditingController(text: c.paymentReference),
      TextEditingController(text: c.paymentDescription),
      TextEditingController(text: c.memberReminderDays.join(',')),
      TextEditingController(text: c.adminReminderDays.join(',')),
      TextEditingController(text: c.notificationTime.substring(0, 5)),
    ];
    for (final controller in _controllers) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  String get _title => switch (widget.section) {
    StudioSettingsSection.access => context.l10n.studioAccessSettingsTitle,
    StudioSettingsSection.booking => context.l10n.bookingSettingsTitle,
    StudioSettingsSection.payment => context.l10n.paymentSettingsTitle,
    StudioSettingsSection.reminders => context.l10n.reminderSettingsTitle,
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(title: _title, onClose: _close),
            Flexible(child: SingleChildScrollView(child: _fields())),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('save-${widget.section.name}-settings'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(context.l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _fields() => switch (widget.section) {
    StudioSettingsSection.access => Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.l10n.allowJoinByCode),
          subtitle: Text(context.l10n.allowJoinByCodeDescription),
          value: _joinEnabled,
          onChanged: (value) => setState(() {
            _joinEnabled = value;
            _dirty = true;
          }),
        ),
        _field(
          _controllers[0],
          context.l10n.labelStudioCode,
          enabled: _joinEnabled,
        ),
      ],
    ),
    StudioSettingsSection.booking => _field(
      _controllers[1],
      context.l10n.cancellationCutoffHoursLabel,
      number: true,
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        return number != null && number >= 0 && number <= 168
            ? null
            : context.l10n.cancellationCutoffHoursValidation;
      },
    ),
    StudioSettingsSection.payment => Column(
      children: [
        _field(_controllers[2], context.l10n.recipientLabel),
        _field(_controllers[3], 'IBAN'),
        _field(_controllers[4], context.l10n.paymentModelLabel),
        _field(_controllers[5], context.l10n.paymentReferenceLabel),
        _field(_controllers[6], context.l10n.paymentDescriptionLabel),
      ],
    ),
    StudioSettingsSection.reminders => Column(
      children: [
        _field(_controllers[7], context.l10n.memberReminderDaysLabel),
        _field(_controllers[8], context.l10n.adminReminderDaysLabel),
        _field(_controllers[9], context.l10n.sendTimeLabel),
      ],
    ),
  };

  Widget _field(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    bool number = false,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: enabled && !_saving,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? context.l10n.requiredField
              : null,
    ),
  );

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty && !await _confirmDiscard(context)) return;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      List<int> days(String value) => value
          .split(',')
          .map((item) => int.parse(item.trim()))
          .toList(growable: false);
      final old = widget.configuration;
      final updated = switch (widget.section) {
        StudioSettingsSection.access => old.copyWith(
          joinByCodeEnabled: _joinEnabled,
          joinCode: _controllers[0].text.trim(),
        ),
        StudioSettingsSection.booking => old.copyWith(
          cancellationCutoffHours: int.parse(_controllers[1].text.trim()),
        ),
        StudioSettingsSection.payment => old.copyWith(
          recipientName: _controllers[2].text.trim(),
          iban: _controllers[3].text.trim(),
          paymentModel: _controllers[4].text.trim(),
          paymentReference: _controllers[5].text.trim(),
          paymentDescription: _controllers[6].text.trim(),
        ),
        StudioSettingsSection.reminders => old.copyWith(
          memberReminderDays: days(_controllers[7].text),
          adminReminderDays: days(_controllers[8].text),
          notificationTime: _controllers[9].text.trim(),
        ),
      };
      await widget.dataSource.updateConfiguration(updated);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizedError(context, error))));
      }
    }
  }
}

Future<bool> showClassTypesModal(
  BuildContext context,
  WidgetRef ref,
  List<ClassTypeConfiguration> items,
) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _ClassTypesModal(items: items),
    ) ??
    false;

class _ClassTypesModal extends ConsumerStatefulWidget {
  const _ClassTypesModal({required this.items});
  final List<ClassTypeConfiguration> items;

  @override
  ConsumerState<_ClassTypesModal> createState() => _ClassTypesModalState();
}

class _ClassTypesModalState extends ConsumerState<_ClassTypesModal> {
  final _form = GlobalKey<FormState>();
  late final List<_ClassTypeDraft> _items;
  final _deletedIds = <int>[];
  final _deletedItems = <int, ClassTypeConfiguration>{};
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map(_ClassTypeDraft.new).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .9,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              _SheetHeader(
                title: context.l10n.classTypesSettingsTitle,
                onClose: _close,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (_, index) => _ClassTypeEditor(
                    key: ValueKey(
                      'class-type-editor-${_items[index].id ?? index}',
                    ),
                    draft: _items[index],
                    onChanged: _changed,
                    onDelete: () => _delete(index),
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('add-class-type'),
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.addClassType),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    key: const ValueKey('save-class-types'),
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(context.l10n.actionSave),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _changed() => setState(() => _dirty = true);
  void _add() => setState(() {
    _items.add(_ClassTypeDraft.empty());
    _dirty = true;
  });
  void _delete(int index) => setState(() {
    final removed = _items.removeAt(index);
    if (removed.id != null) {
      _deletedIds.add(removed.id!);
      _deletedItems[removed.id!] = removed.value;
    }
    removed.dispose();
    _dirty = true;
  });

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty && !await _confirmDiscard(context)) return;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final result = await ref
        .read(studioConfigurationRepositoryProvider)
        .saveClassTypes(_items.map((item) => item.value).toList(), _deletedIds);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case FailureResult(failure: final failure):
        setState(() => _saving = false);
        if (failure.statusCode == 409 && _deletedIds.isNotEmpty) {
          final deactivate = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(context.l10n.classTypesSettingsTitle),
              content: Text(context.l10n.classTypeDeleteConflict),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(context.l10n.actionCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(context.l10n.deactivateMembershipPlan),
                ),
              ],
            ),
          );
          if (deactivate == true && mounted) {
            setState(() {
              for (final id in _deletedIds) {
                final item = _deletedItems[id]!;
                _items.add(
                  _ClassTypeDraft(
                    ClassTypeConfiguration(
                      id: item.id,
                      name: item.name,
                      description: item.description,
                      defaultDurationMinutes: item.defaultDurationMinutes,
                      defaultCapacity: item.defaultCapacity,
                      difficultyLevel: item.difficultyLevel,
                      status: 'inactive',
                    ),
                  ),
                );
              }
              _deletedIds.clear();
              _deletedItems.clear();
            });
            await _save();
          }
          return;
        }
        final message = failure.localized(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _ClassTypeEditor extends StatelessWidget {
  const _ClassTypeEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onDelete,
  });
  final _ClassTypeDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      initiallyExpanded: draft.id == null,
      title: Text(
        draft.name.text.isEmpty ? context.l10n.addClassType : draft.name.text,
      ),
      subtitle: Text(
        draft.status == 'active'
            ? context.l10n.statusActive
            : context.l10n.statusInactive,
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _text(draft.name, context.l10n.classTypeNameLabel, context, onChanged),
        _text(
          draft.description,
          context.l10n.descriptionLabel,
          context,
          onChanged,
          required: false,
        ),
        Row(
          children: [
            Expanded(
              child: _text(
                draft.duration,
                context.l10n.durationMinutesLabel,
                context,
                onChanged,
                number: true,
                positive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _text(
                draft.capacity,
                context.l10n.defaultCapacityLabel,
                context,
                onChanged,
                number: true,
                positive: true,
              ),
            ),
          ],
        ),
        DropdownButtonFormField<String>(
          initialValue: draft.difficulty,
          decoration: InputDecoration(
            labelText: context.l10n.difficultyLevelLabel,
          ),
          items:
              {
                    'beginner': context.l10n.difficultyBeginner,
                    'intermediate': context.l10n.difficultyIntermediate,
                    'advanced': context.l10n.difficultyAdvanced,
                    'all_levels': context.l10n.difficultyAllLevels,
                  }.entries
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.key,
                      child: Text(item.value),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            draft.difficulty = value!;
            onChanged();
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: draft.status,
          decoration: InputDecoration(labelText: context.l10n.statusLabel),
          items: [
            DropdownMenuItem(
              value: 'active',
              child: Text(context.l10n.statusActive),
            ),
            DropdownMenuItem(
              value: 'inactive',
              child: Text(context.l10n.statusInactive),
            ),
          ],
          onChanged: (value) {
            draft.status = value!;
            onChanged();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: Text(context.l10n.deleteItem),
          ),
        ),
      ],
    ),
  );
}

class _ClassTypeDraft {
  _ClassTypeDraft(ClassTypeConfiguration item)
    : id = item.id,
      name = TextEditingController(text: item.name),
      description = TextEditingController(text: item.description ?? ''),
      duration = TextEditingController(
        text: item.defaultDurationMinutes.toString(),
      ),
      capacity = TextEditingController(text: item.defaultCapacity.toString()),
      difficulty = item.difficultyLevel,
      status = item.status;
  _ClassTypeDraft.empty()
    : id = null,
      name = TextEditingController(),
      description = TextEditingController(),
      duration = TextEditingController(text: '60'),
      capacity = TextEditingController(text: '10'),
      difficulty = 'all_levels',
      status = 'active';
  final int? id;
  final TextEditingController name, description, duration, capacity;
  String difficulty, status;
  ClassTypeConfiguration get value => ClassTypeConfiguration(
    id: id,
    name: name.text,
    description: description.text,
    defaultDurationMinutes: int.parse(duration.text),
    defaultCapacity: int.parse(capacity.text),
    difficultyLevel: difficulty,
    status: status,
  );
  void dispose() {
    name.dispose();
    description.dispose();
    duration.dispose();
    capacity.dispose();
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      IconButton(
        tooltip: context.l10n.actionClose,
        onPressed: onClose,
        icon: const Icon(Icons.close),
      ),
    ],
  );
}

Widget _text(
  TextEditingController controller,
  String label,
  BuildContext context,
  VoidCallback onChanged, {
  bool required = true,
  bool number = false,
  bool positive = false,
  bool enabled = true,
  String? Function(String?)? validator,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextFormField(
    controller: controller,
    enabled: enabled,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true, signed: true)
        : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) => onChanged(),
    validator:
        validator ??
        (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return context.l10n.requiredField;
          if (positive && (int.tryParse(text) ?? 0) <= 0) {
            return context.l10n.positiveNumberRequired;
          }
          if (number && text.isNotEmpty && _double(text) == null) {
            return context.l10n.invalidNumber;
          }
          return null;
        },
  ),
);

double? _double(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

Future<bool> _confirmDiscard(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.discardChangesTitle),
        content: Text(context.l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.discardAction),
          ),
        ],
      ),
    ) ??
    false;
