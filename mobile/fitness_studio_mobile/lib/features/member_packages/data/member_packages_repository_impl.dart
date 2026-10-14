import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_exception.dart';
import '../../membership_plans/data/membership_plan_model.dart';
import '../domain/entities/member_package.dart';
import '../domain/repositories/member_packages_repository.dart';
import 'member_packages_remote_data_source.dart';

class MemberPackagesRepositoryImpl implements MemberPackagesRepository {
  const MemberPackagesRepositoryImpl(this._remote);

  final MemberPackagesDataSource _remote;

  @override
  Future<Result<MemberPackageOverview>> getOverview() => _guard(() async {
    final responses = await Future.wait([
      _remote.getMembers(),
      _remote.getMemberships(),
      _remote.getPlans(),
    ]);
    return MemberPackageOverview(
      members: responses[0]
          .map((value) => _member(value as Map<String, dynamic>))
          .toList(growable: false),
      memberships: responses[1]
          .map((value) => _membership(value as Map<String, dynamic>))
          .toList(growable: false),
      plans: responses[2]
          .map(
            (value) =>
                MembershipPlanModel.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  });

  @override
  Future<Result<void>> assignPackage(MemberMembershipDraft draft) =>
      _guard(() => _remote.createMembership(_draft(draft)));

  @override
  Future<Result<void>> changePackage(
    int membershipId,
    MemberMembershipDraft draft,
  ) => _guard(() => _remote.updateMembership(membershipId, _draft(draft)));

  static PackageMember _member(Map<String, dynamic> json) => PackageMember(
    id: (json['id'] as num).toInt(),
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    status: json['status'] as String,
  );

  static MemberMembership _membership(Map<String, dynamic> json) =>
      MemberMembership(
        id: (json['id'] as num).toInt(),
        memberId: (json['memberId'] as num).toInt(),
        membershipPlanId: (json['membershipPlanId'] as num).toInt(),
        membershipPlanName: json['membershipPlanName'] as String,
        startsOn: DateTime.parse(json['startsOn'] as String),
        endsOn: _date(json['endsOn']),
        billingStartsOn: _date(json['billingStartsOn']),
        nextBillingOn: _date(json['nextBillingOn']),
        isActive: json['isActive'] as bool,
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static Map<String, dynamic> _draft(MemberMembershipDraft draft) => {
    'memberId': draft.memberId,
    'membershipPlanId': draft.membershipPlanId,
    'startsOn': _formatDate(draft.startsOn),
    'endsOn': draft.endsOn == null ? null : _formatDate(draft.endsOn!),
    'nextBillingOn': null,
  };

  static String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }
}
