import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/member_packages/data/member_packages_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/member_packages/data/member_packages_repository_impl.dart';
import 'package:fitness_studio_mobile/features/member_packages/domain/entities/member_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads members, memberships and plans into one overview', () async {
    final source = _DataSource();
    final result = await MemberPackagesRepositoryImpl(source).getOverview();

    final overview = (result as Success<MemberPackageOverview>).value;
    expect(overview.members.single.fullName, 'Ana Horvat');
    expect(overview.activeMembershipFor(7)?.membershipPlanName, 'Mjesečni');
    expect(overview.plans.single.priceAmount, 40);
  });

  test(
    'serializes assignment and change payloads with date-only values',
    () async {
      final source = _DataSource();
      final repository = MemberPackagesRepositoryImpl(source);
      final draft = MemberMembershipDraft(
        memberId: 7,
        membershipPlanId: 4,
        startsOn: DateTime(2026, 10, 5, 22, 30),
        endsOn: DateTime(2027, 1, 5),
      );

      await repository.assignPackage(draft);
      await repository.changePackage(31, draft);

      expect(source.created, {
        'memberId': 7,
        'membershipPlanId': 4,
        'startsOn': '2026-10-05',
        'endsOn': '2027-01-05',
        'nextBillingOn': null,
      });
      expect(source.updatedId, 31);
      expect(source.updated, source.created);
    },
  );
}

class _DataSource implements MemberPackagesDataSource {
  Map<String, dynamic>? created;
  Map<String, dynamic>? updated;
  int? updatedId;

  @override
  Future<List<dynamic>> getMembers() async => [
    {
      'id': 7,
      'firstName': 'Ana',
      'lastName': 'Horvat',
      'email': 'ana@example.com',
      'status': 'active',
    },
  ];

  @override
  Future<List<dynamic>> getMemberships() async => [
    {
      'id': 31,
      'memberId': 7,
      'memberName': 'Ana Horvat',
      'membershipPlanId': 4,
      'membershipPlanName': 'Mjesečni',
      'startsOn': '2026-10-01',
      'endsOn': null,
      'billingStartsOn': '2026-10-01',
      'nextBillingOn': '2026-11-01',
      'isActive': true,
    },
  ];

  @override
  Future<List<dynamic>> getPlans() async => [
    {
      'id': 4,
      'name': 'Mjesečni',
      'description': null,
      'billingPeriodMonths': 1,
      'sessionLimit': 8,
      'sessionLimitPeriod': 'month',
      'priceAmount': 40,
      'currency': 'EUR',
      'status': 'active',
    },
  ];

  @override
  Future<void> createMembership(Map<String, dynamic> data) async {
    created = data;
  }

  @override
  Future<void> updateMembership(int id, Map<String, dynamic> data) async {
    updatedId = id;
    updated = data;
  }
}
