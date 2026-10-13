import 'package:fitness_studio_mobile/features/profile/domain/entities/profile.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/state/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('profile is reloaded after its screen is removed', (
    tester,
  ) async {
    var loads = 0;
    late StateSetter setState;
    var showProfile = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith((ref) async {
            loads += 1;
            return _profile(loads == 1 ? 'Ana' : 'Filip');
          }),
        ],
        child: localizedTestApp(
          home: StatefulBuilder(
            builder: (context, update) {
              setState = update;
              return showProfile
                  ? const ProfileScreen()
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Horvat'), findsOneWidget);
    expect(loads, 1);

    setState(() => showProfile = false);
    await tester.pump();
    await tester.pump();
    setState(() => showProfile = true);
    await tester.pumpAndSettle();

    expect(find.text('Filip Horvat'), findsOneWidget);
    expect(find.text('Ana Horvat'), findsNothing);
    expect(loads, 2);
  });
}

Profile _profile(String firstName) => Profile(
  user: const ProfileUser(
    id: 1,
    email: 'trainer@example.com',
    roles: ['trainer'],
  ),
  studio: const ProfileStudio(id: 1, name: 'Stay Fit'),
  member: null,
  trainer: ProfilePerson(
    id: 7,
    firstName: firstName,
    lastName: 'Horvat',
    email: 'trainer@example.com',
    phone: null,
    status: 'active',
  ),
  membership: null,
  usage: null,
  fixedSchedules: const [],
);
