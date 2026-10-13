import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/studio_settings_remote_data_source.dart';
import '../state/studio_settings_provider.dart';

class StudioSettingsScreen extends ConsumerStatefulWidget {
  const StudioSettingsScreen({super.key});

  @override
  ConsumerState<StudioSettingsScreen> createState() =>
      _StudioSettingsScreenState();
}

class _StudioSettingsScreenState extends ConsumerState<StudioSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _recipient = TextEditingController();
  final _iban = TextEditingController();
  final _model = TextEditingController();
  final _reference = TextEditingController();
  final _description = TextEditingController();
  final _memberDays = TextEditingController();
  final _adminDays = TextEditingController();
  final _time = TextEditingController();

  bool _initialized = false;
  bool _joinByCodeEnabled = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _code,
      _recipient,
      _iban,
      _model,
      _reference,
      _description,
      _memberDays,
      _adminDays,
      _time,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuration = ref.watch(studioConfigurationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.studioSettingsTitle)),
      body: configuration.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(studioConfigurationProvider),
        ),
        data: (value) {
          _initialize(value);
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _sectionTitle(context.l10n.studioAccessSettingsTitle),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.allowJoinByCode),
                  subtitle: Text(context.l10n.allowJoinByCodeDescription),
                  value: _joinByCodeEnabled,
                  onChanged: _saving
                      ? null
                      : (enabled) =>
                            setState(() => _joinByCodeEnabled = enabled),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _code,
                  enabled: _joinByCodeEnabled && !_saving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: context.l10n.labelStudioCode,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (code) =>
                      _joinByCodeEnabled ? _required(code) : null,
                ),
                const SizedBox(height: 32),
                _sectionTitle(context.l10n.paymentSettingsTitle),
                const SizedBox(height: 12),
                _field(_recipient, context.l10n.recipientLabel),
                _field(_iban, 'IBAN'),
                _field(_model, context.l10n.paymentModelLabel),
                _field(_reference, context.l10n.paymentReferenceLabel),
                _field(_description, context.l10n.paymentDescriptionLabel),
                const SizedBox(height: 20),
                _sectionTitle(context.l10n.reminderSettingsTitle),
                const SizedBox(height: 12),
                _field(_memberDays, context.l10n.memberReminderDaysLabel),
                _field(_adminDays, context.l10n.adminReminderDaysLabel),
                _field(_time, context.l10n.sendTimeLabel),
                const SizedBox(height: 4),
                FilledButton.icon(
                  key: const ValueKey('studio-settings-save'),
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

  void _initialize(StudioConfiguration value) {
    if (_initialized) return;
    _initialized = true;
    _joinByCodeEnabled = value.joinByCodeEnabled;
    _code.text = value.joinCode ?? '';
    _recipient.text = value.recipientName;
    _iban.text = value.iban;
    _model.text = value.paymentModel;
    _reference.text = value.paymentReference;
    _description.text = value.paymentDescription;
    _memberDays.text = value.memberReminderDays.join(',');
    _adminDays.text = value.adminReminderDays.join(',');
    _time.text = value.notificationTime.substring(0, 5);
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: Theme.of(context).textTheme.titleMedium);

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: _required,
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? context.l10n.requiredField : null;

  Future<void> _save(StudioConfiguration old) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      List<int> days(String value) =>
          value.split(',').map((item) => int.parse(item.trim())).toList();

      await ref
          .read(studioSettingsRemoteProvider)
          .updateConfiguration(
            StudioConfiguration(
              joinByCodeEnabled: _joinByCodeEnabled,
              joinCode: _code.text.trim(),
              recipientName: _recipient.text.trim(),
              iban: _iban.text.trim(),
              paymentModel: _model.text.trim(),
              paymentReference: _reference.text.trim(),
              paymentDescription: _description.text.trim(),
              memberReminderDays: days(_memberDays.text),
              adminReminderDays: days(_adminDays.text),
              notificationTime: _time.text.trim(),
              isPaymentComplete: old.isPaymentComplete,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.settingsSaved)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizedError(context, error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
