import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_controller.dart';
import 'package:fitness_studio_mobile/features/auth/presentation/state/login_state.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/state/member_bookings_provider.dart';
import 'package:fitness_studio_mobile/navigation/app_router.dart';
import 'package:fitness_studio_mobile/navigation/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/localized_test_app.dart';

void main() {
  testWidgets('authenticated app starts on My Workouts tab', (tester) async {
    final container = ProviderContainer(
      overrides: [
        loginControllerProvider.overrideWith(_LoggedInMemberController.new),
        memberBookingsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedRouterTestApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.myWorkouts,
    );
    expect(find.text('Moji treninzi'), findsWidgets);
  });
}

class _LoggedInMemberController extends LoginController {
  @override
  LoginState build() => LoginSuccess(
    AuthSession(
      accessToken: 'token',
      expiresAt: DateTime(2031),
      user: const AuthenticatedUser(
        id: 4,
        studioId: 1,
        memberId: 10,
        trainerId: null,
        email: 'ana.horvat@stayfitjoyful.demo',
        roles: ['member'],
      ),
    ),
  );
}
