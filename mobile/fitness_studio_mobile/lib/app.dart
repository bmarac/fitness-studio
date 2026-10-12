import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/localization.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'navigation/app_router.dart';

class FitnessStudioApp extends ConsumerWidget {
  const FitnessStudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

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
}
