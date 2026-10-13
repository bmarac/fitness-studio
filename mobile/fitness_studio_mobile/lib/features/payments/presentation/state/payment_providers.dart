import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection/service_locator.dart';
import '../../data/payments_remote_data_source.dart';
import '../../domain/entities/membership_payment.dart';

typedef PaymentsQuery = ({bool admin, PaymentView view});

final paymentsProvider =
    FutureProvider.family<List<MembershipPayment>, PaymentsQuery>(
      (ref, query) => serviceLocator<PaymentsRemoteDataSource>().getPayments(
        admin: query.admin,
        view: query.view,
      ),
    );
final paymentSummaryProvider = FutureProvider<MembershipPaymentSummary>(
  (ref) => serviceLocator<PaymentsRemoteDataSource>().getSummary(),
);
final paymentBarcodeProvider = FutureProvider.family<Uint8List, int>(
  (ref, id) => serviceLocator<PaymentsRemoteDataSource>().barcode(id),
);
final billingMembershipsProvider = FutureProvider<List<MembershipBillingItem>>(
  (ref) => serviceLocator<PaymentsRemoteDataSource>().getMemberships(),
);
final billingNotificationsProvider = FutureProvider<List<BillingNotification>>(
  (ref) => serviceLocator<PaymentsRemoteDataSource>().getNotifications(),
);
