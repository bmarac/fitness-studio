import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/class_type.dart';
import '../../domain/repositories/class_types_repository.dart';

final classTypesRepositoryProvider = Provider<ClassTypesRepository>(
  (_) => serviceLocator<ClassTypesRepository>(),
);

final classTypesProvider = FutureProvider.autoDispose<List<ClassType>>((
  ref,
) async {
  final result = await ref.read(classTypesRepositoryProvider).getClassTypes();
  return switch (result) {
    Success(value: final items) => items,
    FailureResult(failure: final failure) => throw failure,
  };
});
