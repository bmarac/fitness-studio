import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/membership_plans/data/membership_plans_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/membership_plans/data/membership_plans_repository_impl.dart';
import 'package:fitness_studio_mobile/features/membership_plans/domain/entities/membership_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repository maps responses and sends the complete plan payload',
    () async {
      final dataSource = _FakeMembershipPlansDataSource();
      final repository = MembershipPlansRepositoryImpl(dataSource);
      const draft = MembershipPlanDraft(
        name: '  Novi paket ',
        description: '  Opis ',
        sessionLimit: 6,
        sessionLimitPeriod: 'week',
        priceAmount: 35.5,
        status: 'active',
      );

      final created = await repository.createPlan(draft);
      final plans = await repository.getPlans();
      await repository.updatePlan(17, draft);
      await repository.deletePlan(17);

      expect(created, isA<Success<MembershipPlan>>());
      expect((plans as Success<List<MembershipPlan>>).value.single.id, 17);
      expect(dataSource.createdData, {
        'name': 'Novi paket',
        'description': 'Opis',
        'billingPeriodMonths': 1,
        'sessionLimit': 6,
        'sessionLimitPeriod': 'week',
        'priceAmount': 35.5,
        'currency': 'EUR',
        'status': 'active',
      });
      expect(dataSource.updatedId, 17);
      expect(dataSource.updatedData, dataSource.createdData);
      expect(dataSource.deletedId, 17);
    },
  );
}

class _FakeMembershipPlansDataSource implements MembershipPlansDataSource {
  Map<String, dynamic>? createdData;
  Map<String, dynamic>? updatedData;
  int? updatedId;
  int? deletedId;

  static const response = <String, dynamic>{
    'id': 17,
    'name': 'Novi paket',
    'description': 'Opis',
    'billingPeriodMonths': 1,
    'sessionLimit': 6,
    'sessionLimitPeriod': 'week',
    'priceAmount': 35.5,
    'currency': 'EUR',
    'status': 'active',
  };

  @override
  Future<List<dynamic>> getPlans() async => [response];

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async {
    createdData = data;
    return response;
  }

  @override
  Future<void> updatePlan(int id, Map<String, dynamic> data) async {
    updatedId = id;
    updatedData = data;
  }

  @override
  Future<void> deletePlan(int id) async {
    deletedId = id;
  }
}
