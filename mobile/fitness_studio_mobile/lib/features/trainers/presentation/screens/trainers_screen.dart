import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../domain/entities/trainer_management.dart';
import '../state/trainers_management_providers.dart';

class TrainersScreen extends ConsumerWidget {
  const TrainersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainers = ref.watch(managedTrainersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.trainersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.createTrainerPath);
          ref.invalidate(managedTrainersProvider);
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(context.l10n.addTrainer),
      ),
      body: trainers.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(managedTrainersProvider),
        ),
        data: (trainers) {
          if (trainers.isEmpty) {
            return Center(child: Text(context.l10n.noTrainersYet));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(managedTrainersProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: trainers
                  .map(
                    (trainer) => ListTile(
                      leading: CircleAvatar(
                        child: Text(trainer.firstName.characters.first),
                      ),
                      title: Text(trainer.fullName),
                      subtitle: Text(trainer.email),
                    ),
                  )
                  .toList(growable: false),
            ),
          );
        },
      ),
    );
  }
}

class CreateTrainerScreen extends ConsumerStatefulWidget {
  const CreateTrainerScreen({super.key});

  @override
  ConsumerState<CreateTrainerScreen> createState() =>
      _CreateTrainerScreenState();
}

class _CreateTrainerScreenState extends ConsumerState<CreateTrainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _phone, _bio]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.addTrainer)),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _text(_firstName, context.l10n.firstName, required: true),
          const SizedBox(height: 12),
          _text(_lastName, context.l10n.lastName, required: true),
          const SizedBox(height: 12),
          _text(_email, context.l10n.labelEmail, required: true, email: true),
          const SizedBox(height: 12),
          _text(_phone, context.l10n.phoneLabel),
          const SizedBox(height: 12),
          _text(_bio, context.l10n.bioLabel, lines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(context.l10n.saveAction),
          ),
        ],
      ),
    ),
  );

  Widget _text(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool email = false,
    int lines = 1,
  }) => TextFormField(
    controller: controller,
    maxLines: lines,
    keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
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
  );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(trainersManagementRepositoryProvider)
        .createTrainer(
          TrainerDraft(
            firstName: _firstName.text,
            lastName: _lastName.text,
            email: _email.text,
            phone: _phone.text,
            bio: _bio.text,
          ),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result) {
      case Success(value: final trainer):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profileCreated(trainer.fullName)),
          ),
        );
        context.pop();
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}
