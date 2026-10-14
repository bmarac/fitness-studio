import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../data/studio_settings_remote_data_source.dart';
import '../state/studio_settings_provider.dart';
import '../widgets/settings_modals.dart';

class StudioSettingsScreen extends ConsumerWidget {
  const StudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configuration = ref.watch(studioConfigurationProvider);
    final classTypes = ref.watch(classTypeConfigurationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.studioSettingsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(studioConfigurationProvider);
          ref.invalidate(classTypeConfigurationsProvider);
          await Future.wait([
            ref.read(studioConfigurationProvider.future),
            ref.read(classTypeConfigurationsProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            ..._generalCards(context, ref, configuration),
            classTypes.when(
              loading: () => _LoadingSettingsCard(
                title: context.l10n.classTypesSettingsTitle,
                icon: Icons.fitness_center_outlined,
              ),
              error: (error, _) => _ErrorSettingsCard(
                title: context.l10n.classTypesSettingsTitle,
                icon: Icons.fitness_center_outlined,
                error: localizedError(context, error),
                onRetry: () => ref.invalidate(classTypeConfigurationsProvider),
              ),
              data: (items) => _SettingsCard(
                key: const ValueKey('class-types-settings-card'),
                icon: Icons.fitness_center_outlined,
                title: context.l10n.classTypesSettingsTitle,
                subtitle: context.l10n.classTypesSettingsSummary(items.length),
                onTap: () async {
                  final saved = await showClassTypesModal(context, ref, items);
                  if (saved && context.mounted) {
                    ref.invalidate(classTypeConfigurationsProvider);
                    _saved(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _generalCards(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StudioConfiguration> configuration,
  ) => configuration.when(
    loading: () => [
      _LoadingSettingsCard(
        title: context.l10n.studioAccessSettingsTitle,
        icon: Icons.key_outlined,
      ),
      _LoadingSettingsCard(
        title: context.l10n.bookingSettingsTitle,
        icon: Icons.event_busy_outlined,
      ),
      _LoadingSettingsCard(
        title: context.l10n.paymentSettingsTitle,
        icon: Icons.payments_outlined,
      ),
      _LoadingSettingsCard(
        title: context.l10n.reminderSettingsTitle,
        icon: Icons.notifications_active_outlined,
      ),
    ],
    error: (error, _) => [
      for (final (title, icon) in [
        (context.l10n.studioAccessSettingsTitle, Icons.key_outlined),
        (context.l10n.bookingSettingsTitle, Icons.event_busy_outlined),
        (context.l10n.paymentSettingsTitle, Icons.payments_outlined),
        (
          context.l10n.reminderSettingsTitle,
          Icons.notifications_active_outlined,
        ),
      ])
        _ErrorSettingsCard(
          title: title,
          icon: icon,
          error: localizedError(context, error),
          onRetry: () => ref.invalidate(studioConfigurationProvider),
        ),
    ],
    data: (value) => [
      _SettingsCard(
        key: const ValueKey('studio-access-card'),
        icon: Icons.key_outlined,
        title: context.l10n.studioAccessSettingsTitle,
        subtitle: value.joinByCodeEnabled
            ? context.l10n.studioAccessEnabledSummary
            : context.l10n.studioAccessDisabledSummary,
        onTap: () =>
            _openGeneral(context, ref, StudioSettingsSection.access, value),
      ),
      _SettingsCard(
        key: const ValueKey('booking-settings-card'),
        icon: Icons.event_busy_outlined,
        title: context.l10n.bookingSettingsTitle,
        subtitle: context.l10n.bookingSettingsSummary(
          value.cancellationCutoffHours,
        ),
        onTap: () =>
            _openGeneral(context, ref, StudioSettingsSection.booking, value),
      ),
      _SettingsCard(
        key: const ValueKey('payment-settings-card'),
        icon: Icons.payments_outlined,
        title: context.l10n.paymentSettingsTitle,
        subtitle: context.l10n.paymentSettingsSummary(
          value.recipientName,
          value.iban,
        ),
        onTap: () =>
            _openGeneral(context, ref, StudioSettingsSection.payment, value),
      ),
      _SettingsCard(
        key: const ValueKey('reminder-settings-card'),
        icon: Icons.notifications_active_outlined,
        title: context.l10n.reminderSettingsTitle,
        subtitle: context.l10n.reminderSettingsSummary(
          value.notificationTime.substring(0, 5),
        ),
        onTap: () =>
            _openGeneral(context, ref, StudioSettingsSection.reminders, value),
      ),
    ],
  );

  Future<void> _openGeneral(
    BuildContext context,
    WidgetRef ref,
    StudioSettingsSection section,
    StudioConfiguration configuration,
  ) async {
    final saved = await showGeneralSettingsModal(
      context,
      ref,
      section,
      configuration,
    );
    if (saved && context.mounted) {
      ref.invalidate(studioConfigurationProvider);
      _saved(context);
    }
  }

  void _saved(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.configurationSaved)));
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class _LoadingSettingsCard extends StatelessWidget {
  const _LoadingSettingsCard({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _ErrorSettingsCard extends StatelessWidget {
  const _ErrorSettingsCard({
    required this.title,
    required this.icon,
    required this.error,
    required this.onRetry,
  });
  final String title;
  final IconData icon;
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(error),
      trailing: IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
    ),
  );
}
