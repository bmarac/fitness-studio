import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/progress_management.dart';
import '../../domain/repositories/progress_repository.dart';

final progressMembersProvider = FutureProvider<List<ProgressMember>>((
  ref,
) async {
  final result = await serviceLocator<ProgressRepository>().getMembers();
  return switch (result) {
    Success(value: final members) => members,
    FailureResult(failure: final failure) => throw failure,
  };
});

final measurementParametersProvider =
    FutureProvider<List<MeasurementParameter>>((ref) async {
      final result = await serviceLocator<ProgressRepository>()
          .getMeasurementParameters();
      return switch (result) {
        Success(value: final parameters) => parameters,
        FailureResult(failure: final failure) => throw failure,
      };
    });
