import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../domain/entities/progress_management.dart';
import '../state/progress_management_providers.dart';

class MembersProgressScreen extends ConsumerStatefulWidget {
  const MembersProgressScreen({super.key});

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
      appBar: AppBar(title: const Text('Napredak članova')),
      body: members.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: error.toString(),
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
                  decoration: const InputDecoration(
                    labelText: 'Pretraži članove',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('Nema pronađenih članova.')),
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
          AppRoutes.memberProgressPath(member.id),
          extra: member.fullName,
        ),
      ),
    );
  }
}
