import '../../../../core/error/result.dart';
import '../entities/membership_plan.dart';

abstract class MembershipPlansRepository {
  Future<Result<List<MembershipPlan>>> getPlans();
  Future<Result<MembershipPlan>> createPlan(MembershipPlanDraft draft);
  Future<Result<void>> updatePlan(int id, MembershipPlanDraft draft);
  Future<Result<void>> deletePlan(int id);
}
