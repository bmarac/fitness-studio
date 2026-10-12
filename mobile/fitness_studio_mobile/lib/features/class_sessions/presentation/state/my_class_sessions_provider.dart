import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/usecases/get_my_class_sessions.dart';
import '../../domain/usecases/get_class_sessions.dart';
import '../../../recurring_schedules/domain/entities/trainer_option.dart';
import '../../../recurring_schedules/domain/usecases/get_trainers.dart';

final myClassSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  final result = await serviceLocator<GetMyClassSessions>()();

  return switch (result) {
    Success(value: final classSessions) => classSessions,
    FailureResult(failure: final failure) => throw failure,
  };
});

final allClassSessionsProvider = FutureProvider<List<ClassSession>>((
  ref,
) async {
  final result = await serviceLocator<GetClassSessions>()();

  return switch (result) {
    Success(value: final classSessions) => classSessions,
    FailureResult(failure: final failure) => throw failure,
  };
});

final trainerOptionsProvider = FutureProvider<List<TrainerOption>>((ref) async {
  final result = await serviceLocator<GetTrainers>()();

  return switch (result) {
    Success(value: final trainers) =>
      trainers.where((trainer) => trainer.status == 'active').toList(),
    FailureResult(failure: final failure) => throw failure,
  };
});
