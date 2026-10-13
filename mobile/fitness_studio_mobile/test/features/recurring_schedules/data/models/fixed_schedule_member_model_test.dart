import 'package:fitness_studio_mobile/features/recurring_schedules/data/models/fixed_schedule_member_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a fixed schedule member assignment', () {
    final member = FixedScheduleMemberModel.fromJson({
      'id': 91,
      'memberId': 21,
      'memberName': 'Iva Ivić',
    });

    expect(member.assignmentId, 91);
    expect(member.memberId, 21);
    expect(member.memberName, 'Iva Ivić');
  });
}
