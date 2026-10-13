import 'package:fitness_studio_mobile/features/membership_plans/data/membership_plan_model.dart';
import 'package:fitness_studio_mobile/features/membership_plans/domain/entities/membership_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps membership plan response', () {
    final plan = MembershipPlanModel.fromJson(const {
      'id': 17,
      'name': 'Mjesečni',
      'description': 'Osam termina',
      'billingPeriodMonths': 1,
      'sessionLimit': 8,
      'sessionLimitPeriod': 'month',
      'priceAmount': 40,
      'currency': 'EUR',
      'status': 'active',
    });

    expect(plan.id, 17);
    expect(plan.priceAmount, 40.0);
    expect(plan.sessionLimit, 8);
    expect(plan.isActive, isTrue);
  });

  test('draft payload fixes monthly EUR billing and trims optional values', () {
    final json = MembershipPlanModel.draftToJson(
      const MembershipPlanDraft(
        name: '  Neograničeni ',
        description: '  ',
        sessionLimit: null,
        sessionLimitPeriod: 'month',
        priceAmount: 55.5,
        status: 'inactive',
      ),
    );

    expect(json, {
      'name': 'Neograničeni',
      'description': null,
      'billingPeriodMonths': 1,
      'sessionLimit': null,
      'sessionLimitPeriod': null,
      'priceAmount': 55.5,
      'currency': 'EUR',
      'status': 'inactive',
    });
  });
}
