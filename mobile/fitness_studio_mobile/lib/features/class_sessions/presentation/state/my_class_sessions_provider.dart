import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/usecases/get_my_class_sessions.dart';

final myClassSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  final result = await serviceLocator<GetMyClassSessions>()();

  return switch (result) {
    Success(value: final classSessions) => classSessions,
    FailureResult(failure: final failure) => throw failure,
  };
});
