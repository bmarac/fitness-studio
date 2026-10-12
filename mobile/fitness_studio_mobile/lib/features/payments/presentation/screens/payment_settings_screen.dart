import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../data/payments_remote_data_source.dart';
import '../../domain/entities/membership_payment.dart';
import '../state/payment_providers.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});
  @override
  ConsumerState<PaymentSettingsScreen> createState() => _State();
}

class _State extends ConsumerState<PaymentSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _iban = TextEditingController();
  final _model = TextEditingController();
  final _reference = TextEditingController();
  final _description = TextEditingController();
  final _memberDays = TextEditingController();
  final _adminDays = TextEditingController();
  final _time = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  @override
  void dispose() {
    for (final c in [
      _recipient,
      _iban,
      _model,
      _reference,
      _description,
      _memberDays,
      _adminDays,
      _time,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(paymentSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.paymentSettingsTitle)),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(localizedError(context, e))),
        data: (value) {
          if (!_loaded) {
            _loaded = true;
            _recipient.text = value.recipientName;
            _iban.text = value.iban;
            _model.text = value.paymentModel;
            _reference.text = value.paymentReference;
            _description.text = value.paymentDescription;
            _memberDays.text = value.memberReminderDays.join(',');
            _adminDays.text = value.adminReminderDays.join(',');
            _time.text = value.notificationTime.substring(0, 5);
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field(_recipient, context.l10n.recipientLabel),
                _field(_iban, 'IBAN'),
                _field(_model, context.l10n.paymentModelLabel),
                _field(_reference, context.l10n.paymentReferenceLabel),
                _field(_description, context.l10n.paymentDescriptionLabel),
                _field(_memberDays, context.l10n.memberReminderDaysLabel),
                _field(_adminDays, context.l10n.adminReminderDaysLabel),
                _field(_time, context.l10n.sendTimeLabel),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(value),
                  icon: const Icon(Icons.save),
                  label: Text(
                    _saving
                        ? context.l10n.actionSaving
                        : context.l10n.actionSave,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? context.l10n.requiredField : null,
    ),
  );
  Future<void> _save(PaymentSettings old) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      List<int> days(String value) =>
          value.split(',').map((e) => int.parse(e.trim())).toList();
      await serviceLocator<PaymentsRemoteDataSource>().updateSettings(
        PaymentSettings(
          recipientName: _recipient.text.trim(),
          iban: _iban.text.trim(),
          paymentModel: _model.text.trim(),
          paymentReference: _reference.text.trim(),
          paymentDescription: _description.text.trim(),
          memberReminderDays: days(_memberDays.text),
          adminReminderDays: days(_adminDays.text),
          notificationTime: _time.text.trim(),
          isComplete: true,
        ),
      );
      ref.invalidate(paymentSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizedError(context, e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
