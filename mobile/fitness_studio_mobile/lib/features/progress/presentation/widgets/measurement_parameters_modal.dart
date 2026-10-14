import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/progress_management.dart';
import '../../domain/repositories/progress_repository.dart';
import '../state/member_progress_provider.dart';
import '../state/progress_management_providers.dart';

Future<bool> showMeasurementParametersModal(
  BuildContext context,
  WidgetRef ref,
) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const _MeasurementParametersModal(),
    ) ??
    false;

class _MeasurementParametersModal extends ConsumerWidget {
  const _MeasurementParametersModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parameters = ref.watch(measurementParametersProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .9,
      child: parameters.when(
        loading: () => _ModalFrame(
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _ModalFrame(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizedError(context, error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(measurementParametersProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.actionRetry),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (items) => _ParameterEditor(items: items),
      ),
    );
  }
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.measurementParametersSettingsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: context.l10n.actionClose,
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _ParameterEditor extends ConsumerStatefulWidget {
  const _ParameterEditor({required this.items});

  final List<MeasurementParameter> items;

  @override
  ConsumerState<_ParameterEditor> createState() => _ParameterEditorState();
}

class _ParameterEditorState extends ConsumerState<_ParameterEditor> {
  final _formKey = GlobalKey<FormState>();
  late final List<_ParameterDraft> _items;
  var _dirty = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.items.map(_ParameterDraft.fromParameter).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.measurementParametersSettingsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.actionClose,
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.reorderMeasurementParametersHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                itemCount: _items.length,
                onReorder: _reorder,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return ReorderableDelayedDragStartListener(
                    key: item.key,
                    index: index,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(4, 14, 8, 14),
                              child: Icon(Icons.drag_indicator),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    key: ValueKey('parameter-name-$index'),
                                    controller: item.name,
                                    enabled: !_saving,
                                    decoration: InputDecoration(
                                      labelText:
                                          context.l10n.parameterNameLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => _markDirty(),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? context.l10n.requiredField
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    key: ValueKey('parameter-unit-$index'),
                                    controller: item.unit,
                                    enabled: !_saving,
                                    decoration: InputDecoration(
                                      labelText: context.l10n.unitLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => _markDirty(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Switch(
                                  key: ValueKey('parameter-active-$index'),
                                  value: item.active,
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(() {
                                          item.active = value;
                                          _dirty = true;
                                        }),
                                ),
                                Text(
                                  item.active
                                      ? context.l10n.statusActive
                                      : context.l10n.statusInactive,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('add-measurement-parameter'),
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _items.add(_ParameterDraft.empty(_items.length));
                          _dirty = true;
                        }),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addMeasurementParameter),
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('save-measurement-parameters'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving
                        ? context.l10n.actionSaving
                        : context.l10n.actionSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      _items.insert(newIndex, _items.removeAt(oldIndex));
      _dirty = true;
    });
  }

  Future<void> _close() async {
    if (_saving) return;
    if (_dirty && !await _confirmDiscard(context)) return;
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final parameters = [
      for (var index = 0; index < _items.length; index++)
        _items[index].toParameter(index),
    ];
    final result = await serviceLocator<ProgressRepository>()
        .saveMeasurementParameters(parameters);
    if (!mounted) return;
    switch (result) {
      case Success():
        ref.invalidate(measurementParametersProvider);
        ref.invalidate(memberProgressProvider);
        Navigator.of(context).pop(true);
      case FailureResult(failure: final failure):
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

class _ParameterDraft {
  _ParameterDraft.fromParameter(MeasurementParameter parameter)
    : key = ValueKey('measurement-parameter-${parameter.id}'),
      id = parameter.id,
      code = parameter.code,
      name = TextEditingController(text: parameter.name),
      unit = TextEditingController(text: parameter.unit ?? ''),
      active = parameter.status == 'active',
      sortOrder = parameter.sortOrder;

  _ParameterDraft.empty(int index)
    : key = UniqueKey(),
      id = 0,
      code = '',
      name = TextEditingController(),
      unit = TextEditingController(),
      active = true,
      sortOrder = index;

  final Key key;
  final int id;
  final String code;
  final TextEditingController name;
  final TextEditingController unit;
  bool active;
  final int sortOrder;

  MeasurementParameter toParameter(int index) => MeasurementParameter(
    id: id,
    code: code,
    name: name.text.trim(),
    unit: unit.text.trim().isEmpty ? null : unit.text.trim(),
    sortOrder: index,
    status: active ? 'active' : 'inactive',
  );

  void dispose() {
    name.dispose();
    unit.dispose();
  }
}

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
