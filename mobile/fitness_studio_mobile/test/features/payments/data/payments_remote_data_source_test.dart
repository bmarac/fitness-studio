import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/payments/data/payments_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/payments/domain/entities/membership_payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reads and parses payments, summary, memberships and notifications',
    () async {
      final adapter = _PaymentsApiAdapter();
      final dataSource = _dataSource(adapter);

      final mine = await dataSource.getPayments(admin: false);
      final reported = await dataSource.getPayments(
        admin: true,
        view: PaymentView.reported,
      );
      final summary = await dataSource.getSummary();
      final memberships = await dataSource.getMemberships();
      final notifications = await dataSource.getNotifications();
      final barcode = await dataSource.barcode(7);

      expect(mine.single.memberName, 'Ana Horvat');
      expect(reported.single.status, 'pending');
      expect(summary.reported, 2);
      expect(memberships.single.planName, 'Mjesečni');
      expect(memberships.single.billingStartsOn, isNull);
      expect(notifications.single.paymentObligationId, 7);
      expect(barcode, [1, 2, 3, 4]);
      final adminRequest = adapter.requests.singleWhere(
        (request) => request.path == '/api/membership-payments',
      );
      expect(adminRequest.queryParameters, {'view': 'reported'});
      expect(
        adapter.requests.map((request) => request.path),
        containsAll([
          '/api/membership-payments/mine',
          '/api/membership-payments/summary',
          '/api/member-memberships',
          '/api/notifications',
          '/api/membership-payments/7/barcode',
        ]),
      );
    },
  );

  test(
    'sends payment transitions and billing payloads to exact routes',
    () async {
      final adapter = _PaymentsApiAdapter();
      final dataSource = _dataSource(adapter);

      await dataSource.report(7);
      await dataSource.confirm(7);
      await dataSource.reject(7);
      await dataSource.reopen(7);
      await dataSource.endMembership(9, DateTime(2026, 10, 31));
      final billing = await dataSource.setBilling(9, DateTime(2026, 10, 1));
      await dataSource.readNotification(12);

      expect(billing.createdObligations, 1);
      expect(billing.nextBillingOn, DateTime(2026, 11, 1));
      expect(
        adapter.requests.map((request) => '${request.method} ${request.path}'),
        [
          'POST /api/membership-payments/7/report',
          'POST /api/membership-payments/7/confirm',
          'POST /api/membership-payments/7/reject-report',
          'POST /api/membership-payments/7/reopen',
          'PUT /api/member-memberships/9/end',
          'PUT /api/member-memberships/9/billing',
          'POST /api/notifications/12/read',
        ],
      );
      expect(adapter.requests[4].data, {'endsOn': '2026-10-31'});
      expect(adapter.requests[5].data, {'firstBillingOn': '2026-10-01'});
    },
  );
}

PaymentsRemoteDataSource _dataSource(_PaymentsApiAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return PaymentsRemoteDataSource(
    ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://example.test'),
      accessTokenProvider: const _NoTokenProvider(),
      dio: dio,
    ),
  );
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _PaymentsApiAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.path.endsWith('/barcode')) {
      return ResponseBody.fromBytes(
        [1, 2, 3, 4],
        200,
        headers: {
          Headers.contentTypeHeader: ['image/svg+xml'],
        },
      );
    }

    final Object body = switch (options.path) {
      '/api/membership-payments/mine' ||
      '/api/membership-payments' => [_paymentJson],
      '/api/membership-payments/summary' => {
        'pending': 1,
        'reported': 2,
        'overdue': 3,
        'paid': 4,
      },
      '/api/member-memberships' => [_membershipJson],
      '/api/notifications' => [_notificationJson],
      _ when options.path.endsWith('/billing') => {
        'createdObligations': 1,
        'nextBillingOn': '2026-11-01',
      },
      _ => const <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static const _paymentJson = <String, dynamic>{
    'id': 7,
    'memberMembershipId': 9,
    'memberId': 1,
    'memberName': 'Ana Horvat',
    'planName': 'Mjesečni',
    'periodStartsOn': '2026-10-01',
    'periodEndsOn': '2026-11-01',
    'dueOn': '2026-10-01',
    'fullAmount': 70,
    'amountDue': 70,
    'currency': 'EUR',
    'status': 'pending',
    'isOverdue': false,
    'recipientName': 'Studio',
    'iban': 'HR1723600001101234565',
    'paymentModel': 'HR00',
    'paymentReference': '12345',
    'paymentDescription': 'Članarina',
    'barcodeUrl': '/api/membership-payments/7/barcode',
  };

  static const _membershipJson = <String, dynamic>{
    'id': 9,
    'memberName': 'Ana Horvat',
    'membershipPlanName': 'Mjesečni',
    'startsOn': '2026-01-01',
    'endsOn': null,
    'billingStartsOn': null,
    'nextBillingOn': null,
    'isActive': true,
  };

  static const _notificationJson = <String, dynamic>{
    'id': 12,
    'paymentObligationId': 7,
    'title': 'Članarina',
    'body': 'Čeka uplatu',
    'readAt': null,
    'createdAt': '2026-10-01T09:00:00Z',
  };
}
