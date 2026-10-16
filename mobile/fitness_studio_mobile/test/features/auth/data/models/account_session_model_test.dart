import 'package:fitness_studio_mobile/features/auth/data/models/account_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and serializes refresh credentials', () {
    final model = AccountSessionModel.fromJson(_accountJson);

    expect(model.refreshToken, 'refresh-token');
    expect(model.refreshTokenExpiresAt, DateTime.utc(2026, 11, 15, 10));
    expect(model.toJson()['refreshToken'], 'refresh-token');
  });

  test('accepts a legacy account session without refresh fields', () {
    final legacy = Map<String, dynamic>.of(_accountJson)
      ..remove('refreshToken')
      ..remove('refreshTokenExpiresAt');

    final model = AccountSessionModel.fromJson(legacy);

    expect(model.refreshToken, isNull);
    expect(model.refreshTokenExpiresAt, isNull);
    expect(model.toJson(), isNot(contains('refreshToken')));
  });
}

const _accountJson = <String, dynamic>{
  'accessToken': 'account-token',
  'expiresAt': '2026-10-16T10:15:00Z',
  'refreshToken': 'refresh-token',
  'refreshTokenExpiresAt': '2026-11-15T10:00:00Z',
  'user': {'id': 42, 'email': 'member@example.com'},
  'studios': <Map<String, dynamic>>[],
};
