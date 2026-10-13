import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/result.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/membership_plan.dart';
import '../state/membership_plans_providers.dart';

enum _PlanAction { edit, delete }

class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(membershipPlansProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.membershipPlansTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-membership-plan'),
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addMembershipPlan),
      ),
      body: plans.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(membershipPlansProvider),
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
                      Icons.inventory_2_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Center(child: Text(context.l10n.noMembershipPlans)),
                  ]
                : items
                      .map(
                        (plan) => _MembershipPlanCard(
                          plan: plan,
                          onEdit: () => _openForm(context, ref, plan: plan),
                          onDelete: () => _delete(context, ref, plan),
                        ),
                      )
                      .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(membershipPlansProvider);
    await ref.read(membershipPlansProvider.future);
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    MembershipPlan? plan,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MembershipPlanForm(plan: plan),
    );
    if (saved != true || !context.mounted) return;

    ref.invalidate(membershipPlansProvider);
    _showMessage(
      context,
      plan == null
          ? context.l10n.membershipPlanCreated
          : context.l10n.membershipPlanUpdated,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MembershipPlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteMembershipPlanTitle),
        content: Text(context.l10n.deleteMembershipPlanQuestion(plan.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete-membership-plan'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(membershipPlansRepositoryProvider)
        .deletePlan(plan.id);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(membershipPlansProvider);
        _showMessage(context, context.l10n.membershipPlanDeleted);
      case FailureResult(failure: final failure)
          when failure.statusCode == 409 && plan.isActive:
        await _offerDeactivation(context, ref, plan);
      case FailureResult(failure: final failure):
        _showMessage(context, failure.localized(context));
    }
  }

  Future<void> _offerDeactivation(
    BuildContext context,
    WidgetRef ref,
    MembershipPlan plan,
  ) async {
    final deactivate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.membershipPlanCannotDeleteTitle),
        content: Text(context.l10n.membershipPlanCannotDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('deactivate-membership-plan'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.deactivateMembershipPlan),
          ),
        ],
      ),
    );
    if (deactivate != true || !context.mounted) return;

    final result = await ref
        .read(membershipPlansRepositoryProvider)
        .updatePlan(plan.id, plan.toDraft(status: 'inactive'));
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(membershipPlansProvider);
        _showMessage(context, context.l10n.membershipPlanDeactivated);
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

class _MembershipPlanCard extends StatelessWidget {
  const _MembershipPlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
  });

  final MembershipPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final description = plan.description?.trim();

    return Card(
      key: ValueKey('membership-plan-${plan.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        leading: CircleAvatar(child: const Icon(Icons.inventory_2_outlined)),
        title: Text(
          plan.name,
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
              context.l10n.membershipPlanMonthlyPrice(
                context.formatCurrency(plan.priceAmount, plan.currency),
              ),
            ),
            Text(_limitSummary(context)),
            const SizedBox(height: 6),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text(
                plan.isActive
                    ? context.l10n.statusActive
                    : context.l10n.statusInactive,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<_PlanAction>(
          key: ValueKey('membership-plan-menu-${plan.id}'),
          onSelected: (action) => switch (action) {
            _PlanAction.edit => onEdit(),
            _PlanAction.delete => onDelete(),
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _PlanAction.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.edit_outlined),
                title: Text(context.l10n.actionEdit),
              ),
            ),
            PopupMenuItem(
              value: _PlanAction.delete,
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

  String _limitSummary(BuildContext context) {
    final limit = plan.sessionLimit;
    if (limit == null) return context.l10n.membershipPlanUnlimited;
    return context.l10n.membershipPlanLimitSummary(
      limit,
      _periodLabel(context, plan.sessionLimitPeriod ?? 'membership'),
    );
  }
}

class _MembershipPlanForm extends ConsumerStatefulWidget {
  const _MembershipPlanForm({this.plan});

  final MembershipPlan? plan;

  @override
  ConsumerState<_MembershipPlanForm> createState() =>
      _MembershipPlanFormState();
}

class _MembershipPlanFormState extends ConsumerState<_MembershipPlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _limit;
  late bool _hasLimit;
  late bool _active;
  late String _period;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = widget.plan;
    _name = TextEditingController(text: plan?.name ?? '');
    _description = TextEditingController(text: plan?.description ?? '');
    _price = TextEditingController(
      text: plan == null ? '' : plan.priceAmount.toStringAsFixed(2),
    );
    _limit = TextEditingController(text: plan?.sessionLimit?.toString() ?? '');
    _hasLimit = plan?.sessionLimit != null;
    _period = plan?.sessionLimitPeriod ?? 'month';
    _active = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.plan == null
                        ? context.l10n.addMembershipPlan
                        : context.l10n.editMembershipPlan,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  tooltip: context.l10n.actionClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('membership-plan-name'),
              controller: _name,
              enabled: !_saving,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: context.l10n.membershipPlanName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? context.l10n.requiredField
                  : null,
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: const ValueKey('membership-plan-description'),
              controller: _description,
              enabled: !_saving,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.membershipPlanDescription,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('membership-plan-price'),
              controller: _price,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.membershipPlanPrice,
                suffixText: 'EUR',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final price = _parsePrice(value);
                return price == null || price < 0 || price > 99999999.99
                    ? context.l10n.invalidMembershipPlanPrice
                    : null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('membership-plan-limit-enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.membershipPlanLimitEnabled),
              value: _hasLimit,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _hasLimit = value),
            ),
            if (_hasLimit) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('membership-plan-limit'),
                controller: _limit,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.membershipPlanSessionLimit,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final limit = int.tryParse(value?.trim() ?? '');
                  return limit == null || limit <= 0
                      ? context.l10n.invalidMembershipPlanLimit
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('membership-plan-period'),
                initialValue: _period,
                decoration: InputDecoration(
                  labelText: context.l10n.membershipPlanLimitPeriod,
                  border: const OutlineInputBorder(),
                ),
                items: ['week', 'month', 'membership']
                    .map(
                      (period) => DropdownMenuItem(
                        value: period,
                        child: Text(_periodLabel(context, period)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _period = value!),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              key: const ValueKey('membership-plan-active'),
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.membershipPlanActive),
              value: _active,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _active = value),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('save-membership-plan'),
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _saving ? context.l10n.actionSaving : context.l10n.actionSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = MembershipPlanDraft(
      name: _name.text,
      description: _description.text,
      sessionLimit: _hasLimit ? int.parse(_limit.text.trim()) : null,
      sessionLimitPeriod: _hasLimit ? _period : null,
      priceAmount: _parsePrice(_price.text)!,
      status: _active ? 'active' : 'inactive',
    );
    final repository = ref.read(membershipPlansRepositoryProvider);
    final failure = widget.plan == null
        ? switch (await repository.createPlan(draft)) {
            Success() => null,
            FailureResult(failure: final failure) => failure,
          }
        : switch (await repository.updatePlan(widget.plan!.id, draft)) {
            Success() => null,
            FailureResult(failure: final failure) => failure,
          };

    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = failure.localized(context);
    });
  }

  double? _parsePrice(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
}

String _periodLabel(BuildContext context, String period) => switch (period) {
  'week' => context.l10n.membershipPlanPeriodWeek,
  'month' => context.l10n.membershipPlanPeriodMonth,
  _ => context.l10n.membershipPlanPeriodMembership,
};
