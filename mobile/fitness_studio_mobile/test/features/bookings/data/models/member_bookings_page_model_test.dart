import 'package:fitness_studio_mobile/features/bookings/data/models/member_bookings_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses paginated member bookings response', () {
    final page = MemberBookingsPageModel.fromJson({
      'items': [
        {
          'id': 31,
          'memberId': 10,
          'memberFirstName': 'Ana',
          'memberLastName': 'Horvat',
          'classSessionId': 21,
          'bookingSource': 'self_service',
          'memberFixedScheduleId': null,
          'classTypeId': 5,
          'classTypeName': 'Pilates',
          'trainerId': 8,
          'trainerFirstName': 'Filip',
          'trainerLastName': 'Šarić',
          'classSessionStartsAt': '2030-10-13T17:00:00Z',
          'classSessionEndsAt': '2030-10-13T18:00:00Z',
          'status': 'booked',
          'bookedAt': '2030-10-12T12:00:00Z',
          'cancelledAt': null,
          'attendedAt': null,
        },
      ],
      'page': 2,
      'pageSize': 20,
      'hasNextPage': true,
    });

    expect(page.items.single.id, 31);
    expect(page.page, 2);
    expect(page.pageSize, 20);
    expect(page.hasNextPage, isTrue);
  });
}
