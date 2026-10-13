import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/account_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/login.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/logout.dart';
import 'package:fitness_studio_mobile/features/auth/domain/usecases/restore_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/studio_membership.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/injection/service_locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  const first = StudioMembership(
    studioId: 1,
    studioName: 'First',
    memberId: 10,
    trainerId: null,
    roles: ['member'],
  );
  const second = StudioMembership(
    studioId: 2,
    studioName: 'Second',
    memberId: null,
    trainerId: 20,
    roles: ['trainer'],
  );

  test('no studios requires join flow', () {
    expect(preferredStudio(const [], null), isNull);
  });

  test('one studio is selected automatically', () {
    expect(preferredStudio(const [first], null)?.studioId, 1);
  });

  test('multiple studios require picker without remembered selection', () {
    expect(preferredStudio(const [first, second], null), isNull);
  });

  test('multiple studios select remembered studio', () {
    expect(preferredStudio(const [first, second], 2)?.studioId, 2);
  });

  group('LoginController', () {
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

    test(
      'restores account and automatically selects remembered studio',
      () async {
        repository.restoreAccountResult = Success(
          AccountSession(
            accessToken: testAccount.accessToken,
            expiresAt: testAccount.expiresAt,
            userId: testAccount.userId,
            email: testAccount.email,
            studios: const [testStudio, otherTestStudio],
          ),
        );
        repository.lastStudioId = 8;
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(loginControllerProvider);
        await _flush();

        expect(repository.selectedStudioId, 8);
        expect(container.read(loginControllerProvider), isA<LoginSuccess>());
      },
    );

    test(
      'keeps account picker when multiple studios have no preference',
      () async {
        final account = AccountSession(
          accessToken: testAccount.accessToken,
          expiresAt: testAccount.expiresAt,
          userId: testAccount.userId,
          email: testAccount.email,
          studios: const [testStudio, otherTestStudio],
        );
        repository.restoreAccountResult = Success(account);
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(loginControllerProvider);
        await _flush();

        expect(
          container.read(loginControllerProvider),
          isA<LoginAccountReady>(),
        );
        expect(repository.selectedStudioId, isNull);
      },
    );

    test('failed explicit selection returns to the account picker', () async {
      repository.restoreAccountResult = Success(testAccount);
      repository.lastStudioId = null;
      repository.selectResult = const FailureResult(
        Failure.remote('Selection failed'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(loginControllerProvider);
      await _flush();

      await container.read(loginControllerProvider.notifier).selectStudio(7);

      expect(container.read(loginControllerProvider), isA<LoginAccountReady>());
    });

    test('successful join immediately selects the joined studio', () async {
      repository.restoreAccountResult = Success(testAccount);
      repository.lastStudioId = null;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(loginControllerProvider);
      await _flush();

      final failure = await container
          .read(loginControllerProvider.notifier)
          .joinStudio(code: 'STAYFIT', firstName: 'Ana', lastName: 'Horvat');

      expect(failure, isNull);
      expect(repository.selectedStudioId, 7);
      expect(container.read(loginControllerProvider), isA<LoginSuccess>());
    });

    test('logout resets state only after repository succeeds', () async {
      repository.restoreSessionResult = Success(testAuthSession);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(loginControllerProvider);
      await _flush();

      expect(
        await container.read(loginControllerProvider.notifier).logout(),
        isNull,
      );
      expect(container.read(loginControllerProvider), isA<LoginInitial>());
    });
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);
