import 'package:fitness_studio_mobile/features/class_sessions/data/models/class_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses recurring schedule lifecycle fields', () {
    final model = ClassSessionModel.fromJson({
      'id': 10,
      'classTypeId': 2,
      'classTypeName': 'Pilates',
      'trainerId': 3,
      'trainerFirstName': 'Ana',
      'trainerLastName': 'Horvat',
      'startsAt': '2026-10-12T16:00:00Z',
      'endsAt': '2026-10-12T17:00:00Z',
      'capacity': 12,
      'bookedCount': 8,
      'status': 'scheduled',
      'recurringScheduleId': 4,
      'recurringScheduleStatus': 'paused',
    });

    expect(model.recurringScheduleId, 4);
    expect(model.recurringScheduleStatus, 'paused');
  });
}
