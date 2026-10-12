import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../domain/entities/membership_payment.dart';

class PaymentsRemoteDataSource {
  const PaymentsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<MembershipPayment>> getPayments({
    required bool admin,
    PaymentView view = PaymentView.all,
  }) async {
    final response = await _api.get<List<dynamic>>(
      admin ? '/api/membership-payments' : '/api/membership-payments/mine',
      queryParameters: admin ? {'view': view.name} : null,
    );
    return (response.data ?? [])
        .map((item) => MembershipPayment.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<MembershipPaymentSummary> getSummary() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/membership-payments/summary',
    );
    return MembershipPaymentSummary.fromJson(response.data!);
  }

  Future<void> report(int id) =>
      _api.post<void>('/api/membership-payments/$id/report');
  Future<void> confirm(int id) =>
      _api.post<void>('/api/membership-payments/$id/confirm');
  Future<void> reject(int id) =>
      _api.post<void>('/api/membership-payments/$id/reject-report');
  Future<void> reopen(int id) =>
      _api.post<void>('/api/membership-payments/$id/reopen');
  Future<void> endMembership(int id, DateTime endsOn) => _api.put<void>(
    '/api/member-memberships/$id/end',
    data: {'endsOn': _date(endsOn)},
  );
  Future<List<MembershipBillingItem>> getMemberships() async {
    final response = await _api.get<List<dynamic>>('/api/member-memberships');
    return (response.data ?? [])
        .map(
          (item) =>
              MembershipBillingItem.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<SetMembershipBillingResult> setBilling(
    int id,
    DateTime firstBillingOn,
  ) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/api/member-memberships/$id/billing',
      data: {'firstBillingOn': _date(firstBillingOn)},
    );
    return SetMembershipBillingResult.fromJson(response.data!);
  }

  Future<List<BillingNotification>> getNotifications() async {
    final response = await _api.get<List<dynamic>>('/api/notifications');
    return (response.data ?? [])
        .map(
          (item) => BillingNotification.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<void> readNotification(int id) =>
      _api.post<void>('/api/notifications/$id/read');
  Future<Uint8List> barcode(int id) async => Uint8List.fromList(
    (await _api.getBytes('/api/membership-payments/$id/barcode')).data ?? [],
  );

  Future<PaymentSettings> getSettings() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/payment-settings',
    );
    return PaymentSettings.fromJson(response.data!);
  }

  Future<void> updateSettings(PaymentSettings value) => _api.put<void>(
    '/api/payment-settings',
    data: {
      'recipientName': value.recipientName,
      'iban': value.iban,
      'paymentModel': value.paymentModel,
      'paymentReference': value.paymentReference,
      'paymentDescription': value.paymentDescription,
      'memberReminderDays': value.memberReminderDays,
      'adminReminderDays': value.adminReminderDays,
      'notificationTime': value.notificationTime,
    },
  );
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
