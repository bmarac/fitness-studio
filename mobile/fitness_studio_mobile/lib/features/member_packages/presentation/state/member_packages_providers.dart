import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/member_package.dart';
import '../../domain/repositories/member_packages_repository.dart';

final memberPackagesRepositoryProvider = Provider<MemberPackagesRepository>(
  (_) => serviceLocator<MemberPackagesRepository>(),
);

final memberPackagesProvider =
    FutureProvider.autoDispose<MemberPackageOverview>((ref) async {
      final result = await ref
          .read(memberPackagesRepositoryProvider)
          .getOverview();
      return switch (result) {
        Success(value: final overview) => overview,
        FailureResult(failure: final failure) => throw failure,
      };
    });
