import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/get_profile.dart';

final profileProvider = FutureProvider<Profile>((ref) async {
  final result = await serviceLocator<GetProfile>()();

  return switch (result) {
    Success(value: final profile) => profile,
    FailureResult(failure: final failure) => throw failure,
  };
});
