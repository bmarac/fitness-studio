import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../injection/service_locator.dart';
import '../../data/studio_settings_remote_data_source.dart';

final studioSettingsRemoteProvider = Provider<StudioSettingsRemoteDataSource>(
  (_) => StudioSettingsRemoteDataSource(serviceLocator()),
);

final studioConfigurationProvider =
    FutureProvider.autoDispose<StudioConfiguration>(
      (ref) => ref.read(studioSettingsRemoteProvider).getConfiguration(),
    );
