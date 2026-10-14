import '../../../../core/error/result.dart';
import '../entities/member_package.dart';

abstract class MemberPackagesRepository {
  Future<Result<MemberPackageOverview>> getOverview();
  Future<Result<void>> assignPackage(MemberMembershipDraft draft);
  Future<Result<void>> changePackage(
    int membershipId,
    MemberMembershipDraft draft,
  );
}
