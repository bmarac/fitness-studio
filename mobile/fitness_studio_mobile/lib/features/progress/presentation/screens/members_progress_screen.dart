import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../domain/entities/progress_management.dart';
import '../state/progress_management_providers.dart';
import '../widgets/measurement_parameters_modal.dart';

class MembersProgressScreen extends ConsumerStatefulWidget {
  const MembersProgressScreen({
    required this.canConfigureParameters,
    super.key,
  });

  final bool canConfigureParameters;

  @override
  ConsumerState<MembersProgressScreen> createState() =>
      _MembersProgressScreenState();
}

class _MembersProgressScreenState extends ConsumerState<MembersProgressScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(progressMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.membersProgressTitle),
        actions: [
          if (widget.canConfigureParameters)
            IconButton(
              key: const ValueKey('measurement-parameters-settings'),
              tooltip: context.l10n.measurementParametersSettingsTitle,
              onPressed: () async {
                final saved = await showMeasurementParametersModal(
                  context,
                  ref,
                );
                if (saved && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.configurationSaved)),
                  );
                }
              },
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
      body: members.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(progressMembersProvider),
        ),
        data: (members) {
          final query = _query.trim().toLowerCase();
          final filtered = members
              .where(
                (member) =>
                    query.isEmpty ||
                    member.fullName.toLowerCase().contains(query) ||
                    member.email.toLowerCase().contains(query),
              )
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () => ref.refresh(progressMembersProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: context.l10n.searchMembers,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text(context.l10n.noMembersFound)),
                  )
                else
                  ...filtered.map((member) => _MemberTile(member: member)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final ProgressMember member;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            '${member.firstName.characters.first}${member.lastName.characters.first}'
                .toUpperCase(),
          ),
        ),
        title: Text(member.fullName),
        subtitle: Text(member.email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          AppRoutes.memberAnthropometryPath(member.id),
          extra: member.fullName,
        ),
      ),
    );
  }
}
