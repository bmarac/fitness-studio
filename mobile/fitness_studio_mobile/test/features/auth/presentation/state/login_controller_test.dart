import 'package:fitness_studio_mobile/features/auth/domain/entities/studio_membership.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const first = StudioMembership(
    studioId: 1,
    studioName: 'First',
    memberId: 10,
    trainerId: null,
    roles: ['member'],
  );
  const second = StudioMembership(
    studioId: 2,
    studioName: 'Second',
    memberId: null,
    trainerId: 20,
    roles: ['trainer'],
  );

  test('no studios requires join flow', () {
    expect(preferredStudio(const [], null), isNull);
  });

  test('one studio is selected automatically', () {
    expect(preferredStudio(const [first], null)?.studioId, 1);
  });

  test('multiple studios require picker without remembered selection', () {
    expect(preferredStudio(const [first, second], null), isNull);
  });

  test('multiple studios select remembered studio', () {
    expect(preferredStudio(const [first, second], 2)?.studioId, 2);
  });
}
