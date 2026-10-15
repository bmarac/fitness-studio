import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/class_type.dart';
import '../state/class_types_providers.dart';

enum _ClassTypeAction { edit, delete }

class ClassTypesScreen extends ConsumerWidget {
  const ClassTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classTypes = ref.watch(classTypesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.classTypesSettingsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-class-type'),
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addClassType),
      ),
      body: classTypes.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(classTypesProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: items.isEmpty
                ? [
                    const SizedBox(height: 160),
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text(context.l10n.noClassTypes)),
                  ]
                : items
                      .map(
                        (item) => _ClassTypeCard(
                          item: item,
                          onEdit: () => _openForm(context, ref, item: item),
                          onDelete: () => _delete(context, ref, item),
                        ),
                      )
                      .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(classTypesProvider);
    await ref.read(classTypesProvider.future);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    ClassType? item,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ClassTypeForm(item: item),
    );
    if (saved != true || !context.mounted) return;

    ref.invalidate(classTypesProvider);
    _showMessage(
      context,
      item == null
          ? context.l10n.classTypeCreated
          : context.l10n.classTypeUpdated,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ClassType item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteClassTypeTitle),
        content: Text(context.l10n.deleteClassTypeQuestion(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-class-type'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(classTypesRepositoryProvider)
        .deleteClassType(item.id);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(classTypesProvider);
        _showMessage(context, context.l10n.classTypeDeleted);
      case FailureResult(failure: final failure)
          when failure.statusCode == 409 && item.isActive:
        await _offerDeactivation(context, ref, item);
      case FailureResult(failure: final failure):
        _showMessage(context, failure.localized(context));
    }
  }

  Future<void> _offerDeactivation(
    BuildContext context,
    WidgetRef ref,
    ClassType item,
  ) async {
    final deactivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.classTypeCannotDeleteTitle),
        content: Text(context.l10n.classTypeDeleteConflict),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('deactivate-class-type'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deactivateMembershipPlan),
          ),
        ],
      ),
    );
    if (deactivate != true || !context.mounted) return;

    final result = await ref
        .read(classTypesRepositoryProvider)
        .updateClassType(item.id, item.toDraft(status: 'inactive'));
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(classTypesProvider);
        _showMessage(context, context.l10n.classTypeDeactivated);
      case FailureResult(failure: final failure):
        _showMessage(context, failure.localized(context));
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ClassTypeCard extends StatelessWidget {
  const _ClassTypeCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassType item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim();

    return Card(
      key: ValueKey('class-type-${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: const CircleAvatar(child: Icon(Icons.fitness_center_outlined)),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(description),
            ],
            const SizedBox(height: 4),
            Text(
              context.l10n.classTypeDefaults(
                item.defaultDurationMinutes,
                item.defaultCapacity,
              ),
            ),
            Text(_difficulty(context, item.difficultyLevel)),
            const SizedBox(height: 6),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                item.isActive
                    ? context.l10n.statusActive
                    : context.l10n.statusInactive,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<_ClassTypeAction>(
          key: ValueKey('class-type-menu-${item.id}'),
          onSelected: (action) => switch (action) {
            _ClassTypeAction.edit => onEdit(),
            _ClassTypeAction.delete => onDelete(),
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _ClassTypeAction.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.l10n.actionEdit),
              ),
            ),
            PopupMenuItem(
              value: _ClassTypeAction.delete,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline),
                title: Text(context.l10n.actionDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _difficulty(BuildContext context, String value) => switch (value) {
    'beginner' => context.l10n.difficultyBeginner,
    'intermediate' => context.l10n.difficultyIntermediate,
    'advanced' => context.l10n.difficultyAdvanced,
    _ => context.l10n.difficultyAllLevels,
  };
}

class _ClassTypeForm extends ConsumerStatefulWidget {
  const _ClassTypeForm({this.item});

  final ClassType? item;

  @override
  ConsumerState<_ClassTypeForm> createState() => _ClassTypeFormState();
}

class _ClassTypeFormState extends ConsumerState<_ClassTypeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _duration;
  late final TextEditingController _capacity;
  late String _difficulty;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _duration = TextEditingController(
      text: (item?.defaultDurationMinutes ?? 60).toString(),
    );
    _capacity = TextEditingController(
      text: (item?.defaultCapacity ?? 10).toString(),
    );
    _difficulty = item?.difficultyLevel ?? 'all_levels';
    _status = item?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    _capacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item == null
                        ? context.l10n.addClassType
                        : context.l10n.editClassType,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.actionClose,
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            _textField(_name, context.l10n.classTypeNameLabel),
            _textField(
              _description,
              context.l10n.descriptionLabel,
              required: false,
              maxLines: 3,
            ),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _duration,
                    context.l10n.durationMinutesLabel,
                    positiveInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    _capacity,
                    context.l10n.defaultCapacityLabel,
                    positiveInteger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _difficulty,
              decoration: InputDecoration(
                labelText: context.l10n.difficultyLevelLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'beginner',
                  child: Text(context.l10n.difficultyBeginner),
                ),
                DropdownMenuItem(
                  value: 'intermediate',
                  child: Text(context.l10n.difficultyIntermediate),
                ),
                DropdownMenuItem(
                  value: 'advanced',
                  child: Text(context.l10n.difficultyAdvanced),
                ),
                DropdownMenuItem(
                  value: 'all_levels',
                  child: Text(context.l10n.difficultyAllLevels),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _difficulty = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: context.l10n.statusLabel,
                border: const OutlineInputBorder(),
              ),
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
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('save-class-type'),
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(context.l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool positiveInteger = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      keyboardType: positiveInteger ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return context.l10n.requiredField;
        if (positiveInteger && (int.tryParse(text) ?? 0) <= 0) {
          return context.l10n.positiveNumberRequired;
        }
        return null;
      },
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final draft = ClassTypeDraft(
      name: _name.text,
      description: _description.text,
      defaultDurationMinutes: int.parse(_duration.text),
      defaultCapacity: int.parse(_capacity.text),
      difficultyLevel: _difficulty,
      status: _status,
    );
    final repository = ref.read(classTypesRepositoryProvider);
    final result = widget.item == null
        ? await repository.createClassType(draft)
        : await repository.updateClassType(widget.item!.id, draft);
    if (!mounted) return;

    switch (result) {
      case Success():
        Navigator.pop(context, true);
      case FailureResult(failure: final failure):
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}
