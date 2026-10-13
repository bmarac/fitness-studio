import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/trainer_management.dart';
import '../../domain/repositories/trainers_management_repository.dart';

final trainersManagementRepositoryProvider =
    Provider<TrainersManagementRepository>(
      (_) => serviceLocator<TrainersManagementRepository>(),
    );

final managedTrainersProvider =
    FutureProvider.autoDispose<List<TrainerSummary>>((ref) async {
      final result = await ref
          .read(trainersManagementRepositoryProvider)
          .getTrainers();
      return switch (result) {
        Success(value: final trainers) => trainers,
        FailureResult(failure: final failure) => throw failure,
      };
    });
