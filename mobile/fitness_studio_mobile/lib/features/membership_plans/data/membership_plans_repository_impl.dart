import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_exception.dart';
import '../domain/entities/membership_plan.dart';
import '../domain/repositories/membership_plans_repository.dart';
import 'membership_plan_model.dart';
import 'membership_plans_remote_data_source.dart';

class MembershipPlansRepositoryImpl implements MembershipPlansRepository {
  const MembershipPlansRepositoryImpl(this._remote);

  final MembershipPlansDataSource _remote;

  @override
  Future<Result<List<MembershipPlan>>> getPlans() => _guard(() async {
    final values = await _remote.getPlans();
    return values
        .map(
          (value) =>
              MembershipPlanModel.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
  });

  @override
  Future<Result<MembershipPlan>> createPlan(MembershipPlanDraft draft) =>
      _guard(() async {
        final value = await _remote.createPlan(
          MembershipPlanModel.draftToJson(draft),
        );
        return MembershipPlanModel.fromJson(value);
      });

  @override
  Future<Result<void>> updatePlan(int id, MembershipPlanDraft draft) =>
      _guard(() async {
        await _remote.updatePlan(id, MembershipPlanModel.draftToJson(draft));
      });

  @override
  Future<Result<void>> deletePlan(int id) => _guard(() async {
    await _remote.deletePlan(id);
  });

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
