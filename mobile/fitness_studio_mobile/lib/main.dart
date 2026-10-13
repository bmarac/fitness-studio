import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/push_notifications_service.dart';
import 'injection/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await serviceLocator<PushNotificationsService>().initialize();

  runApp(const ProviderScope(child: FitnessStudioApp()));
}
