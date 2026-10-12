import 'package:fitness_studio_mobile/features/bookings/data/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses member workout details from booking response', () {
    final booking = BookingModel.fromJson({
      'id': 15,
      'memberId': 10,
      'memberFirstName': 'Ana',
      'memberLastName': 'Horvat',
      'classSessionId': 64,
      'bookingSource': 'fixed_schedule',
      'memberFixedScheduleId': 7,
      'classTypeId': 3,
      'classTypeName': 'Trening snage i izdržljivosti',
      'trainerId': 2,
      'trainerFirstName': 'Filip',
      'trainerLastName': 'Šarić',
      'classSessionStartsAt': '2026-10-12T17:00:00Z',
      'classSessionEndsAt': '2026-10-12T18:00:00Z',
      'status': 'booked',
      'bookedAt': '2026-09-28T08:00:00Z',
      'cancelledAt': null,
      'attendedAt': null,
    });

    expect(booking.memberFullName, 'Ana Horvat');
    expect(booking.classTypeName, 'Trening snage i izdržljivosti');
    expect(booking.trainerFullName, 'Filip Šarić');
    expect(
      booking.classSessionStartsAt.toUtc(),
      DateTime.utc(2026, 10, 12, 17),
    );
    expect(booking.classSessionEndsAt.toUtc(), DateTime.utc(2026, 10, 12, 18));
    expect(booking.status, 'booked');
    expect(booking.cancelledAt, isNull);
    expect(booking.attendedAt, isNull);
  });
}
