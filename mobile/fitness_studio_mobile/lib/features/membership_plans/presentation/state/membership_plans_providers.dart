import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/repositories/membership_plans_repository.dart';

final membershipPlansRepositoryProvider = Provider<MembershipPlansRepository>(
  (_) => serviceLocator<MembershipPlansRepository>(),
);

final membershipPlansProvider =
    FutureProvider.autoDispose<List<MembershipPlan>>((ref) async {
      final result = await ref
          .read(membershipPlansRepositoryProvider)
          .getPlans();
      return switch (result) {
        Success(value: final plans) => plans,
        FailureResult(failure: final failure) => throw failure,
      };
    });
