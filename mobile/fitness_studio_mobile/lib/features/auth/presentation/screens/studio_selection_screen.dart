import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../domain/entities/studio_membership.dart';
import '../state/login_controller.dart';
import '../state/login_state.dart';

class StudioSelectionScreen extends ConsumerStatefulWidget {
  const StudioSelectionScreen({super.key});

  @override
  ConsumerState<StudioSelectionScreen> createState() =>
      _StudioSelectionScreenState();
}

class _StudioSelectionScreenState extends ConsumerState<StudioSelectionScreen> {
  final _code = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  StudioLookup? _lookup;
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final studios = state is LoginAccountReady
        ? state.session.studios
        : const <StudioMembership>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.chooseStudioTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (studios.isNotEmpty) ...[
            Text(
              context.l10n.yourStudios,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final studio in studios)
              Card(
                child: ListTile(
                  title: Text(studio.studioName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _loading
                      ? null
                      : () => ref
                            .read(loginControllerProvider.notifier)
                            .selectStudio(studio.studioId),
                ),
              ),
            const SizedBox(height: 24),
          ],
          Text(
            context.l10n.joinStudioTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: context.l10n.labelStudioCode,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_lookup?.requiresProfileDetails ?? false) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _firstName,
              decoration: InputDecoration(
                labelText: context.l10n.firstName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastName,
              decoration: InputDecoration(
                labelText: context.l10n.lastName,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          if (_lookup case final lookup?) ...[
            const SizedBox(height: 12),
            Text(context.l10n.joinStudioConfirmation(lookup.studioName)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading
                ? null
                : (_lookup == null ? _lookupCode : _join),
            child: Text(
              _lookup == null
                  ? context.l10n.checkStudioCode
                  : context.l10n.joinStudioAction,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupCode() async {
    setState(() => _loading = true);
    final result = await ref
        .read(loginControllerProvider.notifier)
        .lookupStudio(_code.text);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success(value: final lookup):
        setState(() => _lookup = lookup);
      case FailureResult(failure: final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }

  Future<void> _join() async {
    if ((_lookup?.requiresProfileDetails ?? false) &&
        (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.firstAndLastNameRequired)),
      );
      return;
    }
    setState(() => _loading = true);
    final failure = await ref
        .read(loginControllerProvider.notifier)
        .joinStudio(
          code: _code.text,
          firstName: _lookup!.requiresProfileDetails ? _firstName.text : null,
          lastName: _lookup!.requiresProfileDetails ? _lastName.text : null,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}
