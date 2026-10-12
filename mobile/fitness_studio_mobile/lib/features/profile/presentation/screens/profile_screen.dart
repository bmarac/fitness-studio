import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../navigation/app_routes.dart';
import '../../../auth/presentation/state/login_controller.dart';
import '../../../progress/domain/entities/member_progress.dart';
import '../../../progress/presentation/state/member_progress_provider.dart';
import '../../domain/entities/profile.dart';
import '../state/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navProfile),
        actions: [
          IconButton(
            tooltip: context.l10n.notificationsTitle,
            onPressed: () => context.push(AppRoutes.notificationsPath),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            tooltip: context.l10n.logoutTooltip,
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: localizedError(context, error),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (profile) => _ProfileContent(
          profile: profile,
          onRefresh: () async {
            ref.invalidate(profileProvider);
            final memberId = profile.member?.id;
            if (memberId != null) {
              ref.invalidate(memberProgressProvider(memberId));
            }
            await ref.read(profileProvider.future);
            if (memberId != null) {
              await ref.read(memberProgressProvider(memberId).future);
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.logoutTitle),
        content: Text(context.l10n.logoutQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.logout),
            label: Text(context.l10n.logoutAction),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    final failure = await ref.read(loginControllerProvider.notifier).logout();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    if (failure != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.localized(context))));
    }
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile, required this.onRefresh});

  final Profile profile;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final person = profile.primaryPerson;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _ProfileHeader(profile: profile, person: person),
          if (profile.membership case final membership?) ...[
            const SizedBox(height: 24),
            _MembershipCard(membership: membership, usage: profile.usage),
            const SizedBox(height: 16),
            const _PaymentsCard(admin: false),
          ],
          if (profile.member case final member?) ...[
            const SizedBox(height: 16),
            _ProgressSummaryCard(memberId: member.id),
          ],
          if (profile.user.roles.any(
            (role) => role == 'trainer' || role == 'admin',
          )) ...[
            const SizedBox(height: 16),
            const _MembersProgressCard(),
          ],
          if (profile.user.roles.contains('admin')) ...[
            const SizedBox(height: 16),
            const _PaymentsCard(admin: true),
            const SizedBox(height: 16),
            const _PaymentSettingsCard(),
          ],
          if (profile.fixedSchedules.isNotEmpty) ...[
            const SizedBox(height: 16),
            _FixedSchedulesCard(schedules: profile.fixedSchedules),
          ],
          if (profile.trainer?.bio case final bio?
              when bio.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _TrainerBioCard(bio: bio),
          ],
        ],
      ),
    );
  }
}

class _MembersProgressCard extends StatelessWidget {
  const _MembersProgressCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: Text(context.l10n.profileMembersProgress),
        subtitle: Text(context.l10n.profileMembersProgressSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.membersProgressPath),
      ),
    );
  }
}

class _PaymentsCard extends StatelessWidget {
  const _PaymentsCard({required this.admin});
  final bool admin;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: Text(
        admin
            ? context.l10n.profileAdminPayments
            : context.l10n.profileMyPayments,
      ),
      subtitle: Text(
        admin
            ? context.l10n.profileAdminPaymentsSubtitle
            : context.l10n.profileMyPaymentsSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('${AppRoutes.paymentsPath}?admin=$admin'),
    ),
  );
}

class _PaymentSettingsCard extends StatelessWidget {
  const _PaymentSettingsCard();
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.account_balance_outlined),
      title: Text(context.l10n.profilePaymentSettings),
      subtitle: Text(context.l10n.profilePaymentSettingsSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.paymentSettingsPath),
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.person});

  final Profile profile;
  final ProfilePerson? person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = person?.fullName ?? profile.user.email;
    final initials = person == null
        ? name.characters.first.toUpperCase()
        : '${person!.firstName.characters.first}${person!.lastName.characters.first}'
              .toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            initials,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(profile.studio.name, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: profile.user.roles
                    .map(
                      (role) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _roleIcon(role),
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(_roleLabel(context, role)),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _roleIcon(String role) {
    return switch (role) {
      'admin' => Icons.admin_panel_settings_outlined,
      'trainer' => Icons.fitness_center,
      _ => Icons.person_outline,
    };
  }

  static String _roleLabel(BuildContext context, String role) {
    return switch (role) {
      'admin' => context.l10n.roleAdmin,
      'trainer' => context.l10n.roleTrainer,
      'member' => context.l10n.roleMember,
      _ => role,
    };
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership, required this.usage});

  final ProfileMembership membership;
  final ProfileUsage? usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      title: context.l10n.profileMyPlan,
      children: [
        Text(
          membership.planName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (membership.planDescription case final description?
            when description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 16),
        if (usage case final usage?) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  _usageTitle(context, usage.period),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Text(
                '${usage.used}/${usage.allowed}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: usage.allowed == 0
                ? 0
                : (usage.used / usage.allowed).clamp(0, 1),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileValidRange(
              context.formatDate(usage.periodStartsOn),
              context.formatDate(usage.periodEndsOn),
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
        _InfoRow(
          icon: Icons.date_range_outlined,
          label: context.l10n.profileValid,
          value: membership.endsOn == null
              ? context.l10n.profileValidFrom(
                  context.formatDate(membership.startsOn),
                )
              : context.l10n.profileValidRange(
                  context.formatDate(membership.startsOn),
                  context.formatDate(membership.endsOn!),
                ),
          isLast: true,
        ),
      ],
    );
  }

  static String _usageTitle(BuildContext context, String period) {
    return switch (period) {
      'week' => context.l10n.profileUsedThisWeek,
      'month' => context.l10n.profileUsedThisMonth,
      _ => context.l10n.profileUsedInMembership,
    };
  }
}

class _ProgressSummaryCard extends ConsumerWidget {
  const _ProgressSummaryCard({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(memberProgressProvider(memberId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.profileProgress,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.profileRefreshProgress,
                  onPressed: () =>
                      ref.invalidate(memberProgressProvider(memberId)),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            progress.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.profileProgressLoadError),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(memberProgressProvider(memberId)),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.actionRetry),
                  ),
                ],
              ),
              data: (progress) => _ProgressSummary(
                progress: progress,
                onOpen: () => context.push(AppRoutes.progressPath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.progress, required this.onOpen});

  final MemberProgress progress;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    if (progress.latestValues.isEmpty) {
      return Text(context.l10n.profileNoMeasurements);
    }

    const preferredCodes = ['weight_kg', 'bmi', 'waist_cm'];
    final preferredValues = preferredCodes
        .map(progress.latestByCode)
        .whereType<ProgressValue>()
        .toList();
    final values = preferredValues.isNotEmpty
        ? preferredValues
        : progress.latestValues.take(3).toList();

    return Column(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) const Divider(height: 20),
          _ProgressSummaryRow(
            value: values[index],
            change: progress.changeFor(values[index].code),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: onOpen,
            icon: const Icon(Icons.show_chart),
            label: Text(context.l10n.profileShowHistory),
          ),
        ),
      ],
    );
  }
}

class _ProgressSummaryRow extends StatelessWidget {
  const _ProgressSummaryRow({required this.value, required this.change});

  final ProgressValue value;
  final double? change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = value.unit == null ? '' : ' ${value.unit}';
    final changeText = change == null
        ? null
        : '${change! > 0 ? '+' : ''}${context.formatNumber(change!, decimalDigits: value.decimalPlaces)}$unit';

    return Row(
      children: [
        Expanded(child: Text(value.name, style: theme.textTheme.bodyLarge)),
        if (changeText != null) ...[
          Icon(
            change! > 0
                ? Icons.arrow_upward
                : change! < 0
                ? Icons.arrow_downward
                : Icons.remove,
            size: 16,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(changeText, style: theme.textTheme.bodySmall),
          const SizedBox(width: 12),
        ],
        Text(
          '${context.formatNumber(value.value, decimalDigits: value.decimalPlaces)}$unit',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FixedSchedulesCard extends StatelessWidget {
  const _FixedSchedulesCard({required this.schedules});

  final List<ProfileFixedSchedule> schedules;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.profileFixedSchedules,
      children: [
        for (var index = 0; index < schedules.length; index++)
          _FixedScheduleRow(
            schedule: schedules[index],
            isLast: index == schedules.length - 1,
          ),
      ],
    );
  }
}

class _FixedScheduleRow extends StatelessWidget {
  const _FixedScheduleRow({required this.schedule, required this.isLast});

  final ProfileFixedSchedule schedule;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_repeat, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_weekday(context, schedule.dayOfWeek)}, ${_shortTime(schedule.startsAtTime)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(schedule.classTypeName),
                Text(schedule.trainerName, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerBioCard extends StatelessWidget {
  const _TrainerBioCard({required this.bio});

  final String bio;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: context.l10n.profileAboutMe,
      children: [Text(bio)],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _weekday(BuildContext context, int value) {
  if (value < DateTime.monday || value > DateTime.sunday) {
    return context.l10n.unknownDay(value);
  }
  return context.formatWeekday(DateTime(2024, 1, value));
}

String _shortTime(String value) {
  return value.length >= 5 ? value.substring(0, 5) : value;
}
