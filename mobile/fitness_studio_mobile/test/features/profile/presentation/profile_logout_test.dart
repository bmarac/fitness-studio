import 'dart:async';

import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/screens/class_sessions_screen.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_controller.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/class_sessions_state.dart';
import 'package:fitness_studio_mobile/features/profile/domain/entities/profile.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/state/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets(
    'logout is available in the Profile app bar and asks for confirmation',
    (tester) async {
      final controller = _LogoutTestController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            loginControllerProvider.overrideWith(() => controller),
            profileProvider.overrideWith((ref) async => _profile),
          ],
          child: localizedTestApp(home: const ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Odjavi se'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Odjavi se'), findsNothing);

      await tester.tap(find.byTooltip('Odjavi se'));
      await tester.pumpAndSettle();
      expect(find.text('Želiš li se odjaviti iz aplikacije?'), findsOneWidget);

      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();
      expect(controller.logoutCalls, 0);
    },
  );

  testWidgets('logout app bar action shows progress and a localized failure', (
    tester,
  ) async {
    final controller = _LogoutTestController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(() => controller),
          profileProvider.overrideWith((ref) async => _profile),
        ],
        child: localizedTestApp(
          locale: const Locale('en'),
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pump();

    expect(controller.logoutCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.complete(const Failure(FailureKind.logout));
    await tester.pumpAndSettle();

    expect(
      find.text('You cannot be logged out right now. Try again.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Log out'), findsOneWidget);
  });

  testWidgets('successful logout finishes the progress state', (tester) async {
    final controller = _LogoutTestController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(() => controller),
          profileProvider.overrideWith((ref) async => _profile),
        ],
        child: localizedTestApp(home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Odjavi se'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odjavi se').last);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    controller.complete(null);
    await tester.pumpAndSettle();

    expect(controller.logoutCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('class sessions screen does not expose logout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginControllerProvider.overrideWith(_LoggedInController.new),
          classSessionsControllerProvider.overrideWith(
            _EmptyClassSessionsController.new,
          ),
        ],
        child: localizedTestApp(home: const ClassSessionsScreen()),
      ),
    );

    expect(find.byIcon(Icons.logout), findsNothing);
    expect(find.byTooltip('Odjavi se'), findsNothing);
  });
}

class _LoggedInController extends LoginController {
  @override
  LoginState build() => _sessionState;
}

class _EmptyClassSessionsController extends ClassSessionsController {
  @override
  ClassSessionsState build() => const ClassSessionsLoaded([]);
}

class _LogoutTestController extends LoginController {
  final _logoutCompleter = Completer<Failure?>();
  int logoutCalls = 0;

  @override
  LoginState build() => _sessionState;

  @override
  Future<Failure?> logout() {
    logoutCalls += 1;
    return _logoutCompleter.future;
  }

  void complete(Failure? failure) => _logoutCompleter.complete(failure);
}

final _sessionState = LoginSuccess(
  AuthSession(
    accessToken: 'token',
    expiresAt: DateTime(2031),
    user: const AuthenticatedUser(
      id: 1,
      studioId: 1,
      memberId: null,
      trainerId: 7,
      email: 'trainer@example.com',
      roles: ['trainer'],
    ),
  ),
);

const _profile = Profile(
  user: ProfileUser(id: 1, email: 'trainer@example.com', roles: ['trainer']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: null,
  trainer: ProfilePerson(
    id: 7,
    firstName: 'Ana',
    lastName: 'Horvat',
    email: 'trainer@example.com',
    phone: null,
    status: 'active',
  ),
  membership: null,
  usage: null,
  fixedSchedules: [],
);
