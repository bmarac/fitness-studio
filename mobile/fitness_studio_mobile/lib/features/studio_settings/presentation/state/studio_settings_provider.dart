import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection/service_locator.dart';
import '../../data/studio_settings_remote_data_source.dart';
import '../../domain/configuration_items.dart';
import '../../domain/studio_configuration_repository.dart';
import '../../../../core/error/result.dart';

final studioSettingsRemoteProvider = Provider<StudioSettingsRemoteDataSource>(
  (_) => StudioSettingsRemoteDataSource(serviceLocator()),
);

final studioConfigurationProvider =
    FutureProvider.autoDispose<StudioConfiguration>(
      (ref) => ref.read(studioSettingsRemoteProvider).getConfiguration(),
    );

final studioConfigurationRepositoryProvider =
    Provider<StudioConfigurationRepository>(
      (_) => serviceLocator<StudioConfigurationRepository>(),
    );

final classTypeConfigurationsProvider =
    FutureProvider.autoDispose<List<ClassTypeConfiguration>>((ref) async {
      final result = await ref
          .read(studioConfigurationRepositoryProvider)
          .getClassTypes();
      return switch (result) {
        Success(value: final items) => items,
        FailureResult(failure: final failure) => throw failure,
      };
    });
