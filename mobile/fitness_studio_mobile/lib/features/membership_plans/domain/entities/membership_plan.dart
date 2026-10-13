class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.billingPeriodMonths,
    required this.sessionLimit,
    required this.sessionLimitPeriod,
    required this.priceAmount,
    required this.currency,
    required this.status,
  });

  final int id;
  final String name;
  final String? description;
  final int billingPeriodMonths;
  final int? sessionLimit;
  final String? sessionLimitPeriod;
  final double priceAmount;
  final String currency;
  final String status;

  bool get isActive => status == 'active';

  MembershipPlanDraft toDraft({String? status}) => MembershipPlanDraft(
    name: name,
    description: description,
    sessionLimit: sessionLimit,
    sessionLimitPeriod: sessionLimitPeriod,
    priceAmount: priceAmount,
    status: status ?? this.status,
  );
}

class MembershipPlanDraft {
  const MembershipPlanDraft({
    required this.name,
    required this.description,
    required this.sessionLimit,
    required this.sessionLimitPeriod,
    required this.priceAmount,
    required this.status,
  });

  final String name;
  final String? description;
  final int? sessionLimit;
  final String? sessionLimitPeriod;
  final double priceAmount;
  final String status;
}
