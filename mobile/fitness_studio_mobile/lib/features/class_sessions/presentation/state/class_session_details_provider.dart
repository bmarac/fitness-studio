import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/usecases/get_class_session.dart';

final classSessionDetailsProvider = FutureProvider.family<ClassSession, int>((
  ref,
  classSessionId,
) async {
  final result = await serviceLocator<GetClassSession>()(classSessionId);

  return switch (result) {
    Success(value: final classSession) => classSession,
    FailureResult(failure: final failure) => throw failure,
  };
});
