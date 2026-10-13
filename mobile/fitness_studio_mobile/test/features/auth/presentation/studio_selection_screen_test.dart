import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/account_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/studio_membership.dart';
import 'package:fitness_studio_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/login.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/logout.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/screens/studio_selection_screen.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';
import '../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() async {
    await serviceLocator.reset();
    repository = FakeAuthRepository();
    serviceLocator
      ..registerSingleton<AuthRepository>(repository)
      ..registerSingleton(Login(repository))
      ..registerSingleton(Logout(repository))
      ..registerSingleton(RestoreSession(repository));
  });

  tearDown(() => serviceLocator.reset());

  testWidgets('shows account studios and selects a tapped studio', (
    tester,
  ) async {
    repository.restoreAccountResult = Success(
      _account(const [testStudio, otherTestStudio]),
    );
    await _pump(tester);

    expect(find.text('Tvoji studiji'), findsOneWidget);
    expect(find.text('Stay Fit'), findsOneWidget);
    expect(find.text('Second Studio'), findsOneWidget);

    await tester.tap(find.text('Second Studio'));
    await tester.pumpAndSettle();

    expect(repository.selectedStudioId, 8);
  });

  testWidgets('lookup reveals profile fields and validates both names', (
    tester,
  ) async {
    repository.restoreAccountResult = Success(_account(const []));
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'stayfit');
    await tester.tap(find.text('Provjeri kod'));
    await tester.pumpAndSettle();

    expect(repository.lookupCode, 'stayfit');
    expect(find.text('Ime'), findsOneWidget);
    expect(find.text('Prezime'), findsOneWidget);
    expect(find.textContaining('Stay Fit'), findsOneWidget);

    await tester.tap(find.text('Pridruži se'));
    await tester.pump();

    expect(find.text('Unesi ime i prezime.'), findsOneWidget);
    expect(repository.joinArguments, isNull);
  });

  testWidgets('submits joined studio with entered profile details', (
    tester,
  ) async {
    repository.restoreAccountResult = Success(_account(const []));
    await _pump(tester);
    await tester.enterText(find.byType(TextField).first, 'STAYFIT');
    await tester.tap(find.text('Provjeri kod'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), ' Ana ');
    await tester.enterText(find.byType(TextField).at(2), ' Horvat ');
    await tester.tap(find.text('Pridruži se'));
    await tester.pumpAndSettle();

    expect(repository.joinArguments, (
      code: 'STAYFIT',
      firstName: ' Ana ',
      lastName: ' Horvat ',
    ));
    expect(repository.selectedStudioId, 7);
  });

  testWidgets('shows remote lookup error without revealing join fields', (
    tester,
  ) async {
    repository.restoreAccountResult = Success(_account(const []));
    repository.lookupResult = const FailureResult(
      Failure.remote('Studio code is invalid.'),
    );
    await _pump(tester);

    await tester.enterText(find.byType(TextField).first, 'INVALID');
    await tester.tap(find.text('Provjeri kod'));
    await tester.pumpAndSettle();

    expect(find.text('Studio code is invalid.'), findsOneWidget);
    expect(find.text('Ime'), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: localizedTestApp(home: const StudioSelectionScreen())),
  );
  await tester.pumpAndSettle();
}

AccountSession _account(List<StudioMembership> studios) => AccountSession(
  accessToken: testAccount.accessToken,
  expiresAt: testAccount.expiresAt,
  userId: testAccount.userId,
  email: testAccount.email,
  studios: List.unmodifiable(studios),
);
