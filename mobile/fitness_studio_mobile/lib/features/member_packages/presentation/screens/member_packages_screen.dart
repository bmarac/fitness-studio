import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../membership_plans/domain/entities/membership_plan.dart';
import '../../../payments/presentation/state/payment_providers.dart';
import '../../../profile/presentation/state/profile_provider.dart';
import '../../domain/entities/member_package.dart';
import '../state/member_packages_providers.dart';

class MemberPackagesScreen extends ConsumerStatefulWidget {
  const MemberPackagesScreen({super.key});

  @override
  ConsumerState<MemberPackagesScreen> createState() =>
      _MemberPackagesScreenState();
}

class _MemberPackagesScreenState extends ConsumerState<MemberPackagesScreen> {
  String _query = '';
  bool _onlyWithoutPackage = false;

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(memberPackagesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.memberPackagesTitle)),
      body: overview.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(memberPackagesProvider),
        ),
        data: (data) {
          final query = _query.trim().toLowerCase();
          final members = data.members
              .where(
                (member) =>
                    query.isEmpty ||
                    member.fullName.toLowerCase().contains(query) ||
                    member.email.toLowerCase().contains(query),
              )
              .where(
                (member) =>
                    !_onlyWithoutPackage || _isAwaitingPackage(data, member),
              )
              .toList(growable: false);
          members.sort((first, second) {
            final firstPriority = _priority(data, first);
            final secondPriority = _priority(data, second);
            if (firstPriority != secondPriority) {
              return firstPriority.compareTo(secondPriority);
            }
            return first.fullName.compareTo(second.fullName);
          });
          final awaitingCount = data.members
              .where((member) => _isAwaitingPackage(data, member))
              .length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(memberPackagesProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                TextField(
                  key: const ValueKey('member-packages-search'),
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    labelText: context.l10n.searchMembers,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const ValueKey('member-packages-filter-all'),
                      selected: !_onlyWithoutPackage,
                      onSelected: (_) =>
                          setState(() => _onlyWithoutPackage = false),
                      label: Text(context.l10n.memberPackagesFilterAll),
                    ),
                    ChoiceChip(
                      key: const ValueKey('member-packages-filter-missing'),
                      selected: _onlyWithoutPackage,
                      onSelected: (_) =>
                          setState(() => _onlyWithoutPackage = true),
                      label: Text(
                        context.l10n.memberPackagesFilterMissing(awaitingCount),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text(context.l10n.noMembersFound)),
                  )
                else
                  for (final member in members)
                    _MemberPackageCard(
                      member: member,
                      membership: data.activeMembershipFor(member.id),
                      plans: data.plans,
                      onSaved: () => _saved(member),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isAwaitingPackage(
    MemberPackageOverview overview,
    PackageMember member,
  ) => member.isActive && overview.activeMembershipFor(member.id) == null;

  int _priority(MemberPackageOverview overview, PackageMember member) {
    if (_isAwaitingPackage(overview, member)) return 0;
    return member.isActive ? 1 : 2;
  }

  Future<void> _saved(PackageMember member) async {
    ref
      ..invalidate(memberPackagesProvider)
      ..invalidate(profileProvider)
      ..invalidate(billingMembershipsProvider)
      ..invalidate(paymentsProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.memberPackageSaved(member.fullName))),
    );
  }
}

class _MemberPackageCard extends StatelessWidget {
  const _MemberPackageCard({
    required this.member,
    required this.membership,
    required this.plans,
    required this.onSaved,
  });

  final PackageMember member;
  final MemberMembership? membership;
  final List<MembershipPlan> plans;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final current = membership;
    return Card(
      key: ValueKey('member-package-${member.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    '${member.firstName.characters.first}'
                            '${member.lastName.characters.first}'
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(member.email),
                    ],
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    member.isActive
                        ? context.l10n.statusActive
                        : context.l10n.statusInactive,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              current?.membershipPlanName ?? context.l10n.memberPackageMissing,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (current != null)
              Text(
                current.endsOn == null
                    ? context.l10n.memberPackageFrom(
                        context.formatDate(current.startsOn),
                      )
                    : context.l10n.memberPackagePeriod(
                        context.formatDate(current.startsOn),
                        context.formatDate(current.endsOn!),
                      ),
              ),
            if (!member.isActive) ...[
              const SizedBox(height: 8),
              Text(context.l10n.memberPackageInactiveMemberHint),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: ValueKey('manage-member-package-${member.id}'),
                onPressed: member.isActive
                    ? () => _openForm(context, current)
                    : null,
                icon: Icon(current == null ? Icons.add_card : Icons.swap_horiz),
                label: Text(
                  current == null
                      ? context.l10n.assignMemberPackage
                      : context.l10n.changeMemberPackage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    MemberMembership? current,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _MemberPackageForm(member: member, membership: current, plans: plans),
    );
    if (saved == true) onSaved();
  }
}

class _MemberPackageForm extends ConsumerStatefulWidget {
  const _MemberPackageForm({
    required this.member,
    required this.membership,
    required this.plans,
  });

  final PackageMember member;
  final MemberMembership? membership;
  final List<MembershipPlan> plans;

  @override
  ConsumerState<_MemberPackageForm> createState() => _MemberPackageFormState();
}

class _MemberPackageFormState extends ConsumerState<_MemberPackageForm> {
  late int? _planId;
  late DateTime _startsOn;
  late DateTime? _endsOn;
  bool _saving = false;
  String? _error;

  List<MembershipPlan> get _selectablePlans =>
      widget.plans.where((plan) => plan.isActive).toList(growable: false);

  @override
  void initState() {
    super.initState();
    final membership = widget.membership;
    _planId =
        widget.plans.any(
          (plan) => plan.isActive && plan.id == membership?.membershipPlanId,
        )
        ? membership?.membershipPlanId
        : null;
    final now = DateTime.now();
    _startsOn = membership?.startsOn ?? DateTime(now.year, now.month, now.day);
    _endsOn = membership?.endsOn;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final plans = _selectablePlans;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.membership == null
                      ? context.l10n.assignPackageTo(widget.member.fullName)
                      : context.l10n.changePackageFor(widget.member.fullName),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                tooltip: context.l10n.actionClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            Text(context.l10n.noActiveMembershipPlans)
          else
            DropdownButtonFormField<int>(
              key: const ValueKey('member-package-plan'),
              initialValue: _planId,
              decoration: InputDecoration(
                labelText: context.l10n.membershipPlanName,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final plan in plans)
                  DropdownMenuItem(value: plan.id, child: Text(plan.name)),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _planId = value),
            ),
          const SizedBox(height: 12),
          _DateField(
            fieldKey: const ValueKey('member-package-start'),
            label: context.l10n.memberPackageStartsOn,
            value: _startsOn,
            enabled: !_saving,
            onChanged: (value) {
              if (value != null) setState(() => _startsOn = value);
            },
          ),
          const SizedBox(height: 12),
          _DateField(
            fieldKey: const ValueKey('member-package-end'),
            label: context.l10n.memberPackageEndsOn,
            value: _endsOn,
            enabled: !_saving,
            optional: true,
            onChanged: (value) => setState(() => _endsOn = value),
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-member-package'),
            onPressed: _saving || plans.isEmpty ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_planId == null) {
      setState(() => _error = context.l10n.memberPackagePlanRequired);
      return;
    }
    if (_endsOn != null && !_endsOn!.isAfter(_startsOn)) {
      setState(() => _error = context.l10n.memberPackageEndAfterStart);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final draft = MemberMembershipDraft(
      memberId: widget.member.id,
      membershipPlanId: _planId!,
      startsOn: _startsOn,
      endsOn: _endsOn,
    );
    final repository = ref.read(memberPackagesRepositoryProvider);
    final result = widget.membership == null
        ? await repository.assignPackage(draft)
        : await repository.changePackage(widget.membership!.id, draft);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.pop(context, true);
      case FailureResult(failure: final failure):
        setState(() {
          _saving = false;
          _error = failure.localized(context);
        });
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.optional = false,
  });

  final Key fieldKey;
  final String label;
  final DateTime? value;
  final bool enabled;
  final bool optional;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            key: fieldKey,
            onTap: enabled ? () => _pick(context) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                value == null
                    ? context.l10n.memberPackageNoEndDate
                    : context.formatDate(value!),
              ),
            ),
          ),
        ),
        if (optional && value != null)
          IconButton(
            key: const ValueKey('clear-member-package-end'),
            onPressed: enabled ? () => onChanged(null) : null,
            tooltip: context.l10n.memberPackageClearEnd,
            icon: const Icon(Icons.clear),
          ),
      ],
    ),
  );

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (selected != null) onChanged(selected);
  }
}
