import 'package:fitness_studio_mobile/features/profile/domain/entities/profile.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/state/profile_provider.dart';
import 'package:fitness_studio_mobile/features/progress/domain/entities/member_progress.dart';
import 'package:fitness_studio_mobile/features/progress/presentation/state/member_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/localized_test_app.dart';

void main() {
  testWidgets('member profile omits personal details and keeps member cards', (
    tester,
  ) async {
    await _pumpProfile(tester, _memberProfile);

    expect(find.text('Osobni podaci'), findsNothing);
    expect(find.text('Moj paket'), findsOneWidget);
    expect(find.text('Moja članarina'), findsOneWidget);
    expect(find.text('Napredak'), findsOneWidget);
  });

  testWidgets(
    'trainer profile omits personal details and keeps trainer cards',
    (tester) async {
      await _pumpProfile(tester, _trainerProfile);

      expect(find.text('Osobni podaci'), findsNothing);
      expect(find.text('Napredak članova'), findsOneWidget);
      expect(find.text('O meni'), findsOneWidget);
    },
  );

  testWidgets('admin profile omits personal details and keeps admin cards', (
    tester,
  ) async {
    await _pumpProfile(tester, _adminProfile);

    expect(find.text('Osobni podaci'), findsNothing);
    expect(find.text('Naplata članarina'), findsOneWidget);
    expect(find.text('Postavke studija'), findsOneWidget);
    expect(find.text('Postavke plaćanja'), findsNothing);
    expect(find.text('Treneri'), findsOneWidget);
    expect(find.text('Pregledaj i unaprijed dodaj trenere'), findsOneWidget);
  });
}

Future<void> _pumpProfile(WidgetTester tester, Profile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith((ref) async => profile),
        memberProgressProvider.overrideWith(
          (ref, memberId) async =>
              const MemberProgress(latestValues: [], history: []),
        ),
      ],
      child: localizedTestApp(home: const ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

const _member = ProfilePerson(
  id: 11,
  firstName: 'Ana',
  lastName: 'Horvat',
  email: 'ana@example.com',
  phone: '+385 91 555 0101',
  status: 'active',
);

const _trainer = ProfilePerson(
  id: 7,
  firstName: 'Filip',
  lastName: 'Šarić',
  email: 'filip@example.com',
  phone: null,
  status: 'active',
  bio: 'Trener snage i izdržljivosti.',
);

final _memberProfile = Profile(
  user: const ProfileUser(id: 1, email: 'ana@example.com', roles: ['member']),
  studio: const ProfileStudio(id: 1, name: 'Stay Fit'),
  member: _member,
  trainer: null,
  membership: ProfileMembership(
    id: 3,
    planName: 'Grupni trening 2x tjedno',
    planDescription: null,
    startsOn: DateTime(2026),
    endsOn: null,
    isActive: true,
    sessionLimit: 2,
    sessionLimitPeriod: 'week',
  ),
  usage: null,
  fixedSchedules: [],
);

const _trainerProfile = Profile(
  user: ProfileUser(id: 2, email: 'filip@example.com', roles: ['trainer']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: null,
  trainer: _trainer,
  membership: null,
  usage: null,
  fixedSchedules: [],
);

const _adminProfile = Profile(
  user: ProfileUser(id: 3, email: 'admin@example.com', roles: ['admin']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: null,
  trainer: null,
  membership: null,
  usage: null,
  fixedSchedules: [],
);
