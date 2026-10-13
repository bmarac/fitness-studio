import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/localization.dart';
import 'core/notifications/push_notifications_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/state/login_controller.dart';
import 'features/auth/presentation/state/login_state.dart';
import 'injection/service_locator.dart';
import 'l10n/app_localizations.dart';
import 'navigation/app_router.dart';

class FitnessStudioApp extends ConsumerStatefulWidget {
  const FitnessStudioApp({super.key, this.pushNotifications});

  final PushNotificationsService? pushNotifications;

  @override
  ConsumerState<FitnessStudioApp> createState() => _FitnessStudioAppState();
}

class _FitnessStudioAppState extends ConsumerState<FitnessStudioApp> {
  StreamSubscription<String>? _routeSubscription;
  String? _pendingRoute;

  PushNotificationsService? get _pushNotifications =>
      widget.pushNotifications ??
      (serviceLocator.isRegistered<PushNotificationsService>()
          ? serviceLocator<PushNotificationsService>()
          : null);

  @override
  void initState() {
    super.initState();
    final notifications = _pushNotifications;
    _pendingRoute = notifications?.takePendingRoute();
    _routeSubscription = notifications?.openedRoutes.listen((route) {
      _pendingRoute = route;
      _openPendingRoute();
    });
  }

  @override
  void dispose() {
    _routeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    ref.listen<LoginState>(loginControllerProvider, (_, next) {
      if (next is LoginSuccess) _scheduleOpenPendingRoute();
    });
    if (ref.read(loginControllerProvider) is LoginSuccess) {
      _scheduleOpenPendingRoute();
    }

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('hr'), Locale('en')],
      localeResolutionCallback: resolveAppLocale,
      debugShowCheckedModeBanner: false,
    );
  }

  void _scheduleOpenPendingRoute() {
    if (_pendingRoute == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingRoute());
  }

  void _openPendingRoute() {
    if (!mounted || _pendingRoute == null) return;
    if (ref.read(loginControllerProvider) is! LoginSuccess) return;
    final route = _pendingRoute!;
    _pendingRoute = null;
    ref.read(appRouterProvider).go(route);
  }
}
