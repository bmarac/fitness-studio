import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/failure_localization.dart';
import 'package:fitness_studio_mobile/core/l10n/localization.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_test_app.dart';

void main() {
  test('resolves Croatian, English and unsupported locales', () {
    const supported = [Locale('hr'), Locale('en')];

    expect(
      resolveAppLocale(const Locale('hr', 'HR'), supported),
      const Locale('hr'),
    );
    expect(
      resolveAppLocale(const Locale('en', 'US'), supported),
      const Locale('en'),
    );
    expect(
      resolveAppLocale(const Locale('de', 'DE'), supported),
      const Locale('hr'),
    );
    expect(resolveAppLocale(null, supported), const Locale('hr'));
  });

  testWidgets('renders the login screen in Croatian and English', (
    tester,
  ) async {
    Future<void> pump(Locale locale) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_InitialLoginController.new),
        ],
        child: localizedTestApp(locale: locale, home: const LoginScreen()),
      ),
    );

    await pump(const Locale('hr'));
    expect(find.text('Prijavi se u svoj studio'), findsOneWidget);
    expect(find.text('Lozinka'), findsOneWidget);

    await pump(const Locale('en'));
    expect(find.text('Sign in to your studio'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('unsupported device locale falls back to Croatian', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_InitialLoginController.new),
        ],
        child: localizedTestApp(
          locale: const Locale('de'),
          home: const LoginScreen(),
        ),
      ),
    );

    expect(find.text('Prijavi se u svoj studio'), findsOneWidget);
  });

  testWidgets('formats dates, numbers and plurals for the active locale', (
    tester,
  ) async {
    Widget sample(Locale locale) => localizedTestApp(
      locale: locale,
      home: Builder(
        builder: (context) => Column(
          children: [
            Text(context.formatDate(DateTime(2026, 10, 11))),
            Text(context.formatNumber(1234.5, decimalDigits: 1)),
            Text(context.formatCurrency(70, 'EUR')),
            Text(context.l10n.sessionsCount(2)),
          ],
        ),
      ),
    );

    await tester.pumpWidget(sample(const Locale('hr')));
    expect(find.text('11. 10. 2026.'), findsOneWidget);
    expect(find.text('1.234,5'), findsOneWidget);
    expect(find.text('70,00 €'), findsOneWidget);
    expect(find.text('2 termina'), findsOneWidget);

    await tester.pumpWidget(sample(const Locale('en')));
    expect(find.text('10/11/2026'), findsOneWidget);
    expect(find.text('1,234.5'), findsOneWidget);
    expect(find.text('€70.00'), findsOneWidget);
    expect(find.text('2 classes'), findsOneWidget);
  });

  testWidgets('localizes the duplicate booking API failure', (tester) async {
    const failure = Failure.remote(
      'This member already has an active booking for this class session.',
      statusCode: 409,
    );

    Widget sample(Locale locale) => localizedTestApp(
      locale: locale,
      home: Builder(builder: (context) => Text(failure.localized(context))),
    );

    await tester.pumpWidget(sample(const Locale('hr')));
    expect(find.text('Već ste prijavljeni na ovaj termin.'), findsOneWidget);

    await tester.pumpWidget(sample(const Locale('en')));
    expect(find.text('You are already booked for this class.'), findsOneWidget);
  });

  testWidgets('localizes membership booking failures', (tester) async {
    const missingMembership = Failure.remote(
      'This member does not have a membership that covers the selected class session date.',
      statusCode: 409,
    );
    const limitReached = Failure.remote(
      'This member has reached the session limit for the selected membership period.',
      statusCode: 409,
    );

    Widget sample(Failure failure) => localizedTestApp(
      locale: const Locale('hr'),
      home: Builder(builder: (context) => Text(failure.localized(context))),
    );

    await tester.pumpWidget(sample(missingMembership));
    expect(
      find.text('Nemate paket koji vrijedi na datum ovog termina.'),
      findsOneWidget,
    );

    await tester.pumpWidget(sample(limitReached));
    expect(
      find.text(
        'Iskoristili ste sve termine dostupne u paketu za ovo razdoblje.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('localizes fixed schedule package limit failure', (tester) async {
    const failure = Failure.remote(
      "The member's membership package does not allow another fixed schedule.",
      statusCode: 409,
    );

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('hr'),
        home: Builder(builder: (context) => Text(failure.localized(context))),
      ),
    );

    expect(
      find.text('Paket člana ne dopušta dodatni fiksni termin.'),
      findsOneWidget,
    );
  });

  testWidgets('localizes overlapping membership periods', (tester) async {
    const failure = Failure.remote(
      'This member already has a membership that overlaps the selected period.',
      statusCode: 409,
    );

    await tester.pumpWidget(
      localizedTestApp(
        home: Builder(builder: (context) => Text(failure.localized(context))),
      ),
    );

    expect(
      find.text('Član već ima paket koji se preklapa s odabranim razdobljem.'),
      findsOneWidget,
    );
  });
}

class _InitialLoginController extends LoginController {
  @override
  LoginState build() => const LoginInitial();
}
