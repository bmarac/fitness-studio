import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/trainer_management.dart';
import '../state/trainers_management_providers.dart';

enum _TrainerAction { edit, delete }

class TrainersScreen extends ConsumerWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainers = ref.watch(managedTrainersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trainersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-trainer'),
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(context.l10n.addTrainer),
      ),
      body: trainers.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(managedTrainersProvider),
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
                      Icons.people_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text(context.l10n.noTrainersYet)),
                  ]
                : items
                      .map(
                        (item) => _TrainerCard(
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
    ref.invalidate(managedTrainersProvider);
    await ref.read(managedTrainersProvider.future);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    TrainerSummary? item,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TrainerForm(item: item),
    );
    if (saved != true || !context.mounted) return;

    ref.invalidate(managedTrainersProvider);
    _showMessage(
      context,
      item == null ? context.l10n.trainerCreated : context.l10n.trainerUpdated,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TrainerSummary item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteTrainerTitle),
        content: Text(context.l10n.deleteTrainerQuestion(item.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-trainer'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(trainersManagementRepositoryProvider)
        .deleteTrainer(item.id);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(managedTrainersProvider);
        _showMessage(context, context.l10n.trainerDeleted);
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
    TrainerSummary item,
  ) async {
    final deactivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.trainerCannotDeleteTitle),
        content: Text(context.l10n.trainerDeleteConflict),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('deactivate-trainer'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deactivateMembershipPlan),
          ),
        ],
      ),
    );
    if (deactivate != true || !context.mounted) return;

    final result = await ref
        .read(trainersManagementRepositoryProvider)
        .updateTrainer(item.id, item.toDraft(status: 'inactive'));
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(managedTrainersProvider);
        _showMessage(context, context.l10n.trainerDeactivated);
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

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainerSummary item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final phone = item.phone?.trim();
    final bio = item.bio?.trim();

    return Card(
      key: ValueKey('trainer-${item.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: CircleAvatar(child: Text(item.firstName.characters.first)),
        title: Text(
          item.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(item.email),
            if (phone != null && phone.isNotEmpty) Text(phone),
            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(bio),
            ],
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
        trailing: PopupMenuButton<_TrainerAction>(
          key: ValueKey('trainer-menu-${item.id}'),
          onSelected: (action) => switch (action) {
            _TrainerAction.edit => onEdit(),
            _TrainerAction.delete => onDelete(),
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TrainerAction.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.l10n.actionEdit),
              ),
            ),
            PopupMenuItem(
              value: _TrainerAction.delete,
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
}

class CreateTrainerScreen extends StatelessWidget {
  const CreateTrainerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.addTrainer)),
    body: const _TrainerForm(showHeader: false),
  );
}

class _TrainerForm extends ConsumerStatefulWidget {
  const _TrainerForm({this.item, this.showHeader = true});

  final TrainerSummary? item;
  final bool showHeader;

  @override
  ConsumerState<_TrainerForm> createState() => _TrainerFormState();
}

class _TrainerFormState extends ConsumerState<_TrainerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _firstName = TextEditingController(text: item?.firstName ?? '');
    _lastName = TextEditingController(text: item?.lastName ?? '');
    _email = TextEditingController(text: item?.email ?? '');
    _phone = TextEditingController(text: item?.phone ?? '');
    _bio = TextEditingController(text: item?.bio ?? '');
    _status = item?.status ?? 'active';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _bio.dispose();
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
            if (widget.showHeader)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item == null
                          ? context.l10n.addTrainer
                          : context.l10n.editTrainer,
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
            _textField(_firstName, context.l10n.firstName),
            _textField(_lastName, context.l10n.lastName),
            _textField(
              _email,
              context.l10n.labelEmail,
              keyboardType: TextInputType.emailAddress,
              email: true,
            ),
            _textField(
              _phone,
              context.l10n.phoneLabel,
              required: false,
              keyboardType: TextInputType.phone,
            ),
            _textField(
              _bio,
              context.l10n.bioLabel,
              required: false,
              maxLines: 3,
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
                key: const ValueKey('save-trainer'),
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
    bool email = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return context.l10n.requiredField;
        if (email && (!text.contains('@') || !text.contains('.'))) {
          return context.l10n.invalidEmail;
        }
        return null;
      },
    ),
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final draft = TrainerDraft(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      bio: _bio.text,
      status: _status,
    );
    final repository = ref.read(trainersManagementRepositoryProvider);
    final result = widget.item == null
        ? await repository.createTrainer(draft)
        : await repository.updateTrainer(widget.item!.id, draft);
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
