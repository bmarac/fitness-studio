import '../../../membership_plans/domain/entities/membership_plan.dart';

class PackageMember {
  const PackageMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String status;

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';
}

class MemberMembership {
  const MemberMembership({
    required this.id,
    required this.memberId,
    required this.membershipPlanId,
    required this.membershipPlanName,
    required this.startsOn,
    required this.endsOn,
    required this.billingStartsOn,
    required this.nextBillingOn,
    required this.isActive,
  });

  final int id;
  final int memberId;
  final int membershipPlanId;
  final String membershipPlanName;
  final DateTime startsOn;
  final DateTime? endsOn;
  final DateTime? billingStartsOn;
  final DateTime? nextBillingOn;
  final bool isActive;
}

class MemberPackageOverview {
  const MemberPackageOverview({
    required this.members,
    required this.memberships,
    required this.plans,
  });

  final List<PackageMember> members;
  final List<MemberMembership> memberships;
  final List<MembershipPlan> plans;

  MemberMembership? activeMembershipFor(int memberId) {
    final active =
        memberships
            .where((item) => item.memberId == memberId && item.isActive)
            .toList(growable: false)
          ..sort((a, b) => b.startsOn.compareTo(a.startsOn));
    return active.firstOrNull;
  }
}

class MemberMembershipDraft {
  const MemberMembershipDraft({
    required this.memberId,
    required this.membershipPlanId,
    required this.startsOn,
    required this.endsOn,
  });

  final int memberId;
  final int membershipPlanId;
  final DateTime startsOn;
  final DateTime? endsOn;
}
