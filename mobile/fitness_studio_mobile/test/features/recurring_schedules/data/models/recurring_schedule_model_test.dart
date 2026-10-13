import 'package:fitness_studio_mobile/features/recurring_schedules/data/models/recurring_schedule_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses capacity and active fixed member count', () {
    final schedule = RecurringScheduleModel.fromJson({
      'id': 41,
      'classTypeName': 'Pilates',
      'trainerId': 8,
      'trainerName': 'Ana Horvat',
      'dayOfWeek': 1,
      'startsAtTime': '18:00:00',
      'durationMinutes': 60,
      'capacity': 12,
      'activeMemberCount': 7,
      'validFrom': '2026-10-01',
      'validUntil': null,
      'status': 'active',
      'statusEffectiveFrom': null,
    });

    expect(schedule.durationMinutes, 60);
    expect(schedule.capacity, 12);
    expect(schedule.activeMemberCount, 7);
  });
}
