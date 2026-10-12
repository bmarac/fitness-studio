import 'package:fitness_studio_mobile/core/l10n/localization.dart';
import 'package:fitness_studio_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget localizedTestApp({
  required Widget home,
  Locale locale = const Locale('hr'),
}) => MaterialApp(
  locale: locale,
  localeResolutionCallback: resolveAppLocale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [Locale('hr'), Locale('en')],
  home: home,
);

Widget localizedRouterTestApp({
  required GoRouter router,
  Locale locale = const Locale('hr'),
}) => MaterialApp.router(
  locale: locale,
  localeResolutionCallback: resolveAppLocale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: const [Locale('hr'), Locale('en')],
  routerConfig: router,
);
