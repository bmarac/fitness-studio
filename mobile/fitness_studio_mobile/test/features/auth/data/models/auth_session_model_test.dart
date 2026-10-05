import 'package:fitness_studio_mobile/features/auth/data/models/auth_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and serializes login response', () {
    final json = <String, dynamic>{
      'accessToken': 'token-value',
      'expiresAt': '2026-09-22T14:30:00Z',
      'user': <String, dynamic>{
        'id': 10,
        'studioId': 1,
        'memberId': 2,
        'trainerId': null,
        'email': 'ana.horvat@example.com',
        'roles': ['member'],
      },
    };

    final model = AuthSessionModel.fromJson(json);

    expect(model.accessToken, 'token-value');
    expect(model.expiresAt, DateTime.utc(2026, 9, 22, 14, 30));
    expect(model.user.memberId, 2);
    expect(model.user.roles, ['member']);
    expect(model.toJson(), {...json, 'expiresAt': '2026-09-22T14:30:00.000Z'});
  });

  test('throws for malformed login response', () {
    expect(
      () => AuthSessionModel.fromJson(const {'accessToken': 'token-value'}),
      throwsFormatException,
    );
  });
}
