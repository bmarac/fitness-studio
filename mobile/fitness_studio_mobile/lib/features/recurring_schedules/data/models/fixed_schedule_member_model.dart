import '../../domain/entities/fixed_schedule_member.dart';

class FixedScheduleMemberModel extends FixedScheduleMember {
  const FixedScheduleMemberModel({
    required super.assignmentId,
    required super.memberId,
    required super.memberName,
  });

  factory FixedScheduleMemberModel.fromJson(Map<String, dynamic> json) =>
      FixedScheduleMemberModel(
        assignmentId: json['id'] as int,
        memberId: json['memberId'] as int,
        memberName: json['memberName'] as String,
      );
}
