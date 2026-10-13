import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/network/api_exception.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/payments/data/payments_remote_data_source.dart';
import 'package:test/test.dart';

void main() {
  test('member payment moves from pending through reported to paid', () async {
    final apiBaseUrl = _requiredEnvironmentValue(
      'FITNESS_STUDIO_TEST_API_BASE_URL',
    );
    final tokenProvider = _MutableAccessTokenProvider();
    final apiClient = ApiClient(
      config: AppConfig(apiBaseUrl: apiBaseUrl),
      accessTokenProvider: tokenProvider,
    );
    final auth = AuthRemoteDataSource(apiClient);
    final payments = PaymentsRemoteDataSource(apiClient);

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'filip.saric@stayfitjoyful.demo',
    );
    final memberships = await payments.getMemberships();
    final disabledBilling = memberships.where(
      (membership) => membership.billingStartsOn == null,
    );
    expect(
      disabledBilling,
      isNotEmpty,
      reason: 'The fresh demo database must contain disabled billing.',
    );
    final billing = await payments.setBilling(
      disabledBilling.first.id,
      DateTime.now(),
    );
    expect(billing.createdObligations, greaterThanOrEqualTo(1));

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'ana.horvat@stayfitjoyful.demo',
    );
    final pending = (await payments.getPayments(
      admin: false,
    )).where((payment) => payment.status == 'pending');
    expect(
      pending,
      isNotEmpty,
      reason: 'Ana must have a pending seeded payment obligation.',
    );
    final payment = pending.first;
    final barcode = await payments.barcode(payment.id);
    expect(barcode, isNotEmpty);
    expect(String.fromCharCodes(barcode), contains('<svg'));

    await payments.report(payment.id);
    final reported = (await payments.getPayments(
      admin: false,
    )).singleWhere((candidate) => candidate.id == payment.id);
    expect(reported.status, 'reported');

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'filip.saric@stayfitjoyful.demo',
    );
    await payments.confirm(payment.id);

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'ana.horvat@stayfitjoyful.demo',
    );
    final paid = (await payments.getPayments(
      admin: false,
    )).singleWhere((candidate) => candidate.id == payment.id);
    expect(paid.status, 'paid');
  });
}

Future<AuthSession> _login(
  AuthRemoteDataSource dataSource,
  _MutableAccessTokenProvider tokenProvider, {
  required String apiBaseUrl,
  required String email,
}) async {
  try {
    final account = await dataSource.login(
      email: email,
      password: 'Fitness123!',
    );
    tokenProvider.accessToken = account.accessToken;
    final studio = account.studios.singleWhere((item) => item.studioId == 1);
    final session = await dataSource.selectStudio(studio.studioId);
    tokenProvider.accessToken = session.accessToken;
    return session;
  } on ApiException catch (error) {
    throw TestFailure(
      'Could not log in as $email through $apiBaseUrl: ${error.message}',
    );
  }
}

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh payment-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
