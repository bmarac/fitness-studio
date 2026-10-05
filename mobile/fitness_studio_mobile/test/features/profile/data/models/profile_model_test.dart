import 'package:fitness_studio_mobile/features/profile/data/models/profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses member profile with membership usage and fixed schedules', () {
    final model = ProfileModel.fromJson({
      'user': {
        'id': 4,
        'email': 'ana@example.com',
        'roles': ['member'],
      },
      'studio': {'id': 1, 'name': 'Stay Fit & Joyful'},
      'member': {
        'id': 10,
        'firstName': 'Ana',
        'lastName': 'Horvat',
        'email': 'ana@example.com',
        'phone': '+385 91 555 0101',
        'dateOfBirth': '1992-04-12',
        'status': 'active',
      },
      'trainer': null,
      'membership': {
        'id': 13,
        'planName': 'Grupni trening 2x tjedno',
        'planDescription': 'Dva grupna treninga tjedno.',
        'startsOn': '2026-09-19',
        'endsOn': '2026-10-18',
        'status': 'active',
        'sessionLimit': 2,
        'sessionLimitPeriod': 'week',
      },
      'usage': {
        'periodStartsOn': '2026-09-21',
        'periodEndsOn': '2026-09-27',
        'used': 2,
        'allowed': 2,
        'period': 'week',
      },
      'fixedSchedules': [
        {
          'id': 1,
          'classTypeName': 'Pilates',
          'trainerName': 'Kristina Lisec',
          'dayOfWeek': 1,
          'startsAtTime': '18:00:00',
        },
      ],
    });

    expect(model.primaryPerson?.fullName, 'Ana Horvat');
    expect(model.membership?.sessionLimit, 2);
    expect(model.usage?.used, 2);
    expect(model.fixedSchedules.single.dayOfWeek, 1);
  });

  test('parses trainer profile without member-only sections', () {
    final model = ProfileModel.fromJson({
      'user': {
        'id': 1,
        'email': 'filip@example.com',
        'roles': ['admin', 'trainer'],
      },
      'studio': {'id': 1, 'name': 'Stay Fit & Joyful'},
      'member': null,
      'trainer': {
        'id': 1,
        'firstName': 'Filip',
        'lastName': 'Šarić',
        'email': 'filip@example.com',
        'phone': null,
        'bio': null,
        'status': 'active',
      },
      'membership': null,
      'usage': null,
      'fixedSchedules': <dynamic>[],
    });

    expect(model.primaryPerson?.fullName, 'Filip Šarić');
    expect(model.user.roles, ['admin', 'trainer']);
    expect(model.membership, isNull);
    expect(model.usage, isNull);
    expect(model.fixedSchedules, isEmpty);
  });
}
