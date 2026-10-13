import '../domain/entities/membership_plan.dart';

class MembershipPlanModel extends MembershipPlan {
  const MembershipPlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.billingPeriodMonths,
    required super.sessionLimit,
    required super.sessionLimitPeriod,
    required super.priceAmount,
    required super.currency,
    required super.status,
  });

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json) =>
      MembershipPlanModel(
        id: json['id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        billingPeriodMonths: json['billingPeriodMonths'] as int,
        sessionLimit: json['sessionLimit'] as int?,
        sessionLimitPeriod: json['sessionLimitPeriod'] as String?,
        priceAmount: (json['priceAmount'] as num).toDouble(),
        currency: json['currency'] as String,
        status: json['status'] as String,
      );

  static Map<String, dynamic> draftToJson(MembershipPlanDraft draft) => {
    'name': draft.name.trim(),
    'description': _optional(draft.description),
    'billingPeriodMonths': 1,
    'sessionLimit': draft.sessionLimit,
    'sessionLimitPeriod': draft.sessionLimit == null
        ? null
        : draft.sessionLimitPeriod,
    'priceAmount': draft.priceAmount,
    'currency': 'EUR',
    'status': draft.status,
  };

  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
