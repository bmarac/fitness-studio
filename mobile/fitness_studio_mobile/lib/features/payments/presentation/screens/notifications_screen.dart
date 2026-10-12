import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_localization.dart';
import '../../../../core/l10n/localization.dart';
import '../../../../injection/service_locator.dart';
import '../../data/payments_remote_data_source.dart';
import '../state/payment_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(billingNotificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationsTitle)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(localizedError(context, e))),
        data: (values) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(billingNotificationsProvider),
          child: ListView.builder(
            itemCount: values.length,
            itemBuilder: (context, index) {
              final item = values[index];
              return ListTile(
                leading: Icon(
                  item.readAt == null
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.readAt == null ? FontWeight.w700 : null,
                  ),
                ),
                subtitle: Text(item.body),
                onTap: item.readAt != null
                    ? null
                    : () async {
                        await serviceLocator<PaymentsRemoteDataSource>()
                            .readNotification(item.id);
                        ref.invalidate(billingNotificationsProvider);
                      },
              );
            },
          ),
        ),
      ),
    );
  }
}
