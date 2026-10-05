import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/member_progress.dart';
import '../../domain/usecases/get_member_progress.dart';

final memberProgressProvider = FutureProvider.family<MemberProgress, int>((
  ref,
  memberId,
) async {
  final result = await serviceLocator<GetMemberProgress>()(memberId);

  return switch (result) {
    Success(value: final progress) => progress,
    FailureResult(failure: final failure) => throw failure,
  };
});
