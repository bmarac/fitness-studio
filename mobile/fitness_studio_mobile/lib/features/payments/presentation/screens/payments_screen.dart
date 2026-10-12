import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../data/payments_remote_data_source.dart';
import '../../domain/entities/membership_payment.dart';
import '../state/payment_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, required this.admin});

  final bool admin;

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  PaymentView _view = PaymentView.pending;

  @override
  Widget build(BuildContext context) {
    final query = (
      admin: widget.admin,
      view: widget.admin ? _view : PaymentView.all,
    );
    final payments = ref.watch(paymentsProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.admin
              ? context.l10n.profileAdminPayments
              : context.l10n.profileMyPayments,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentsProvider);
          if (widget.admin) {
            ref.invalidate(paymentSummaryProvider);
            ref.invalidate(billingMembershipsProvider);
          }
        },
        child: payments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(localizedError(context, error)),
              ),
            ],
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.admin) ...[
                _PaymentFilters(
                  selected: _view,
                  onSelected: (value) => setState(() => _view = value),
                ),
                const SizedBox(height: 12),
              ],
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(context.l10n.noPaymentsInCategory)),
                ),
              for (final payment in items)
                _PaymentCard(payment: payment, admin: widget.admin),
              if (widget.admin) ...[
                const SizedBox(height: 12),
                const _BillingActivationSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentFilters extends ConsumerWidget {
  const _PaymentFilters({required this.selected, required this.onSelected});

  final PaymentView selected;
  final ValueChanged<PaymentView> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(paymentSummaryProvider);
    return summary.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(localizedError(context, error)),
      data: (counts) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip(
              PaymentView.pending,
              context.l10n.paymentFilterPending,
              counts.pending,
            ),
            _chip(
              PaymentView.reported,
              context.l10n.paymentFilterReported,
              counts.reported,
            ),
            _chip(
              PaymentView.overdue,
              context.l10n.paymentFilterOverdue,
              counts.overdue,
            ),
            _chip(
              PaymentView.paid,
              context.l10n.paymentFilterPaid,
              counts.paid,
            ),
            _chip(
              PaymentView.all,
              context.l10n.paymentFilterAll,
              counts.pending + counts.reported + counts.overdue + counts.paid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(PaymentView value, String label, int count) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      selected: selected == value,
      onSelected: (_) => onSelected(value),
      label: Text('$label ($count)'),
    ),
  );
}

class _PaymentCard extends ConsumerWidget {
  const _PaymentCard({required this.payment, required this.admin});

  final MembershipPayment payment;
  final bool admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = payment.status == 'paid'
        ? Colors.green
        : payment.isOverdue
        ? Colors.red
        : payment.status == 'reported'
        ? Colors.orange
        : Colors.blue;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: .15),
              foregroundColor: color,
              child: Icon(
                payment.status == 'paid'
                    ? Icons.check
                    : Icons.payments_outlined,
              ),
            ),
            title: Text(
              admin ? payment.memberName : payment.planName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              context.l10n.paymentDueSummary(
                payment.planName,
                _period(context, payment),
                context.formatCurrency(payment.amountDue, payment.currency),
                _status(context, payment),
                context.formatDate(payment.dueOn),
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              _row(context.l10n.paymentRecipient, payment.recipientName),
              _row('IBAN', payment.iban),
              _row(
                context.l10n.paymentModelAndReference,
                '${payment.paymentModel} ${payment.paymentReference}',
              ),
              _row(context.l10n.paymentDescription, payment.paymentDescription),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _barcode(context, ref),
                    icon: const Icon(Icons.qr_code_2),
                    label: Text(context.l10n.paymentCode),
                  ),
                  if (!admin && payment.status == 'pending')
                    FilledButton(
                      onPressed: () => _run(
                        context,
                        ref,
                        () => serviceLocator<PaymentsRemoteDataSource>().report(
                          payment.id,
                        ),
                      ),
                      child: Text(context.l10n.paymentReported),
                    ),
                  if (admin && payment.status == 'reported')
                    OutlinedButton(
                      onPressed: () => _run(
                        context,
                        ref,
                        () => serviceLocator<PaymentsRemoteDataSource>().reject(
                          payment.id,
                        ),
                      ),
                      child: Text(context.l10n.rejectPaymentReport),
                    ),
                  if (admin && payment.status == 'paid')
                    OutlinedButton(
                      onPressed: () => _run(
                        context,
                        ref,
                        () => serviceLocator<PaymentsRemoteDataSource>().reopen(
                          payment.id,
                        ),
                      ),
                      child: Text(context.l10n.reopenPayment),
                    ),
                  if (!admin)
                    OutlinedButton.icon(
                      onPressed: () => _end(context, ref),
                      icon: const Icon(Icons.event_busy),
                      label: Text(context.l10n.endMembership),
                    ),
                ],
              ),
            ],
          ),
          if (admin && payment.status != 'paid')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _confirmPaid(context, ref),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(context.l10n.markPaid),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.markPaid),
        content: Text(
          '${payment.memberName}\n${_period(context, payment)}\n'
          '${context.formatCurrency(payment.amountDue, payment.currency)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(
        context,
        ref,
        () => serviceLocator<PaymentsRemoteDataSource>().confirm(payment.id),
      );
    }
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(paymentsProvider);
      ref.invalidate(paymentSummaryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.changeSaved)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizedError(context, error))));
      }
    }
  }

  Future<void> _barcode(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(paymentBarcodeProvider(payment.id).future);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.hub3PaymentCode),
        content: SizedBox(width: 580, child: SvgPicture.memory(bytes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.actionClose),
          ),
        ],
      ),
    );
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: today,
    );
    if (chosen == null || !context.mounted) return;
    var estimate = payment.amountDue;
    if (payment.status == 'pending' &&
        chosen.isBefore(payment.periodEndsOn) &&
        chosen.isAfter(payment.periodStartsOn)) {
      final total = payment.periodEndsOn
          .difference(payment.periodStartsOn)
          .inDays;
      final used = chosen.difference(payment.periodStartsOn).inDays;
      estimate = payment.fullAmount * used / total;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.endMembership),
        content: Text(
          context.l10n.endMembershipSummary(
            context.formatDate(chosen),
            context.formatCurrency(estimate, payment.currency),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.actionConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(
        context,
        ref,
        () => serviceLocator<PaymentsRemoteDataSource>().endMembership(
          payment.memberMembershipId,
          chosen,
        ),
      );
    }
  }

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

class _BillingActivationSection extends ConsumerWidget {
  const _BillingActivationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(billingMembershipsProvider);
    return memberships.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text(localizedError(context, error)),
      data: (items) {
        final activeMemberships = items.where((item) => item.isActive).toList();
        final disabled = activeMemberships
            .where((item) => item.billingStartsOn == null)
            .toList();
        final enabled = activeMemberships
            .where((item) => item.billingStartsOn != null)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MembershipSection(
              title: context.l10n.billingNotEnabled,
              emptyText: context.l10n.allMembershipsBillingEnabled,
              color: Theme.of(context).colorScheme.secondaryContainer,
              children: [
                for (final item in disabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.memberName),
                    subtitle: Text(
                      '${item.planName}\n${context.l10n.membershipStarted(context.formatDate(item.startsOn))}',
                    ),
                    trailing: FilledButton(
                      onPressed: () => _enable(context, ref, item),
                      child: Text(context.l10n.enableBilling),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _MembershipSection(
              title: context.l10n.activeBilling,
              emptyText: context.l10n.noActiveBilling,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              children: [
                for (final item in enabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.autorenew),
                    title: Text(item.memberName),
                    subtitle: Text(
                      context.l10n.billingStartsSummary(
                        item.planName,
                        context.formatDate(item.billingStartsOn!),
                        item.nextBillingOn == null
                            ? context.l10n.noNextBilling
                            : context.formatDate(item.nextBillingOn!),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _enable(
    BuildContext context,
    WidgetRef ref,
    MembershipBillingItem item,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final latest = item.endsOn?.subtract(const Duration(days: 1));
    final lastDate = latest ?? DateTime(today.year + 10, 12, 31);
    var initial = today.isBefore(item.startsOn) ? item.startsOn : today;
    if (initial.isAfter(lastDate)) initial = lastDate;
    DateTime selected = initial;

    final chosen = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(context.l10n.enableBilling),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.memberName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(item.planName),
              Text(
                context.l10n.membershipStarted(
                  context.formatDate(item.startsOn),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: Text(context.l10n.billingValidFrom),
                subtitle: Text(context.formatDate(selected)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    firstDate: item.startsOn,
                    lastDate: lastDate,
                    initialDate: selected,
                  );
                  if (picked != null) setState(() => selected = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: Text(context.l10n.actionContinue),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;

    if (chosen.isBefore(today)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.retroactiveBilling),
          content: Text(
            context.l10n.retroactiveBillingWarning(context.formatDate(chosen)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.enableBilling),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    try {
      final result = await serviceLocator<PaymentsRemoteDataSource>()
          .setBilling(item.id, chosen);
      ref.invalidate(billingMembershipsProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(paymentSummaryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.createdObligations == 0
                  ? context.l10n.billingEnabled
                  : context.l10n.billingEnabledWithCount(
                      result.createdObligations,
                    ),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizedError(context, error))));
      }
    }
  }
}

class _MembershipSection extends StatelessWidget {
  const _MembershipSection({
    required this.title,
    required this.emptyText,
    required this.color,
    required this.children,
  });

  final String title;
  final String emptyText;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (children.isEmpty) Text(emptyText) else ...children,
        ],
      ),
    ),
  );
}

String _period(BuildContext context, MembershipPayment payment) =>
    '${context.formatDate(payment.periodStartsOn)} – '
    '${context.formatDate(payment.periodEndsOn.subtract(const Duration(days: 1)))}';

String _status(BuildContext context, MembershipPayment item) =>
    item.status == 'paid'
    ? context.l10n.paymentFilterPaid
    : item.status == 'reported'
    ? context.l10n.paymentFilterReported
    : item.isOverdue
    ? context.l10n.paymentFilterOverdue
    : context.l10n.paymentStatusUnpaid;
