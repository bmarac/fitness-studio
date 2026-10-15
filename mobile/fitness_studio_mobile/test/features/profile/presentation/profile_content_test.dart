import 'package:fitness_studio_mobile/features/profile/domain/entities/profile.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:fitness_studio_mobile/features/profile/presentation/state/profile_provider.dart';
import 'package:flutter/material.dart';
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
    expect(find.text('Grupni trening 2x tjedno'), findsOneWidget);
    expect(find.text('Iskorišteno u obračunskom periodu'), findsOneWidget);
    expect(find.text('5/11'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
    expect(find.text('Fiksni termini'), findsOneWidget);
    expect(find.byIcon(Icons.event_repeat), findsNWidgets(2));
    expect(find.text('Ponedjeljak · 19:00'), findsOneWidget);
    expect(find.text('Srijeda · 19:00'), findsOneWidget);
    expect(find.text('Dva grupna treninga tjedno.'), findsNothing);
    expect(find.text('Pilates'), findsNothing);
    expect(find.text('Kristina Lisec'), findsNothing);
    expect(find.text('Moja članarina'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Antropometrija'), 300);
    expect(find.text('Antropometrija'), findsOneWidget);
    expect(find.text('Tjelesna mjerenja'), findsOneWidget);
    expect(find.byIcon(Icons.monitor_heart_outlined), findsOneWidget);
    expect(find.text('Cjenik'), findsNothing);
    expect(find.text('Vrste treninga'), findsNothing);
  });

  testWidgets('fixed schedules are hidden without an active membership', (
    tester,
  ) async {
    await _pumpProfile(tester, _memberWithoutMembershipProfile);

    expect(find.text('Moj paket'), findsNothing);
    expect(find.byType(Chip), findsNothing);
    expect(find.text('Petak · 07:00'), findsNothing);
    expect(find.text('Fiksni termini'), findsNothing);
  });

  testWidgets('fixed schedules section is hidden when there are no schedules', (
    tester,
  ) async {
    await _pumpProfile(tester, _memberWithoutFixedSchedulesProfile);

    expect(find.text('Moj paket'), findsOneWidget);
    expect(find.text('Fiksni termini'), findsNothing);
    expect(find.byIcon(Icons.event_repeat), findsNothing);
  });

  testWidgets(
    'trainer profile omits personal details and keeps trainer cards',
    (tester) async {
      await _pumpProfile(tester, _trainerProfile);

      expect(find.text('Osobni podaci'), findsNothing);
      expect(find.text('Antropometrija članova'), findsOneWidget);
      expect(find.text('O meni'), findsOneWidget);
      expect(find.text('Cjenik'), findsNothing);
      expect(find.text('Vrste treninga'), findsNothing);
    },
  );

  testWidgets('admin profile omits personal details and keeps admin cards', (
    tester,
  ) async {
    await _pumpProfile(tester, _adminProfile);

    expect(find.text('Osobni podaci'), findsNothing);
    expect(find.text('Postavke plaćanja'), findsNothing);
    expect(find.text('Treneri'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vrste treninga'), 300);
    expect(find.text('Vrste treninga'), findsOneWidget);
    expect(find.text('Dodaj i uređuj vrste treninga'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cjenik'), 300);
    expect(find.text('Cjenik'), findsOneWidget);
    expect(find.text('Upravljaj cjenikom'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Članovi i paketi'), 300);
    expect(find.text('Članovi i paketi'), findsOneWidget);
    expect(find.text('Dodijeli ili promijeni paket članu'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Postavke studija'), 300);
    expect(find.text('Postavke studija'), findsOneWidget);
    expect(find.text('Pristup, naplata i podsjetnici'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Naplata članarina'), 300);
    expect(find.text('Naplata članarina'), findsOneWidget);
    expect(find.text('Dodaj i uređuj trenere'), findsOneWidget);
  });
}

Future<void> _pumpProfile(WidgetTester tester, Profile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileProvider.overrideWith((ref) async => profile)],
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

final _membership = ProfileMembership(
  id: 3,
  planName: 'Grupni trening 2x tjedno',
  planDescription: 'Dva grupna treninga tjedno.',
  startsOn: DateTime(2026),
  endsOn: null,
  isActive: true,
  sessionLimit: 2,
  sessionLimitPeriod: 'week',
);

final _memberProfile = Profile(
  user: const ProfileUser(id: 1, email: 'ana@example.com', roles: ['member']),
  studio: const ProfileStudio(id: 1, name: 'Stay Fit'),
  member: _member,
  trainer: null,
  membership: _membership,
  usage: ProfileUsage(
    periodStartsOn: DateTime(2026, 10, 3),
    periodEndsOn: DateTime(2026, 11, 2),
    used: 5,
    allowed: 11,
    period: 'billing_cycle',
  ),
  fixedSchedules: [
    ProfileFixedSchedule(
      id: 1,
      classTypeName: 'Pilates',
      trainerName: 'Kristina Lisec',
      dayOfWeek: 1,
      startsAtTime: '19:00:00',
    ),
    ProfileFixedSchedule(
      id: 2,
      classTypeName: 'Trening snage i izdržljivosti',
      trainerName: 'Filip Šarić',
      dayOfWeek: 3,
      startsAtTime: '19:00:00',
    ),
  ],
);

final _memberWithoutFixedSchedulesProfile = Profile(
  user: const ProfileUser(id: 1, email: 'ana@example.com', roles: ['member']),
  studio: const ProfileStudio(id: 1, name: 'Stay Fit'),
  member: _member,
  trainer: null,
  membership: _membership,
  usage: null,
  fixedSchedules: const [],
);

const _memberWithoutMembershipProfile = Profile(
  user: ProfileUser(id: 1, email: 'ana@example.com', roles: ['member']),
  studio: ProfileStudio(id: 1, name: 'Stay Fit'),
  member: _member,
  trainer: null,
  membership: null,
  usage: null,
  fixedSchedules: [
    ProfileFixedSchedule(
      id: 3,
      classTypeName: 'Pilates',
      trainerName: 'Kristina Lisec',
      dayOfWeek: 5,
      startsAtTime: '07:00:00',
    ),
  ],
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
