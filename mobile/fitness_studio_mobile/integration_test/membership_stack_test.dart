import 'dart:io';

import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/core/network/api_exception.dart';
import 'package:fitness_studio_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/bookings/data/datasources/bookings_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/create_booking.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_sessions.dart';
import 'package:fitness_studio_mobile/features/member_packages/data/member_packages_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/member_packages/data/member_packages_repository_impl.dart';
import 'package:fitness_studio_mobile/features/member_packages/domain/entities/member_package.dart';
import 'package:fitness_studio_mobile/features/payments/data/payments_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:test/test.dart';

void main() {
  test(
    'membership enables booking and ending it blocks another booking',
    () async {
      final apiBaseUrl = _requiredEnvironmentValue(
        'FITNESS_STUDIO_TEST_API_BASE_URL',
      );
      final tokenProvider = _MutableAccessTokenProvider();
      final client = ApiClient(
        config: AppConfig(apiBaseUrl: apiBaseUrl),
        accessTokenProvider: tokenProvider,
      );
      final auth = AuthRemoteDataSource(client);
      final packages = MemberPackagesRepositoryImpl(
        MemberPackagesRemoteDataSource(client),
      );
      final profile = ProfileRepositoryImpl(ProfileRemoteDataSource(client));
      final getSessions = GetClassSessions(
        ClassSessionsRepositoryImpl(ClassSessionsRemoteDataSource(client)),
      );
      final createBooking = CreateBooking(
        BookingsRepositoryImpl(BookingsRemoteDataSource(client)),
      );
      final payments = PaymentsRemoteDataSource(client);

      const memberEmail = 'membership.stack@example.test';
      const memberPassword = 'MembershipStack123!';
      final registered = await auth.register(
        email: memberEmail,
        password: memberPassword,
      );
      tokenProvider.accessToken = registered.accessToken;
      final lookup = await auth.lookupStudio('STAYFIT');
      expect(lookup.role, 'member');
      final joined = await auth.joinStudio(
        code: 'STAYFIT',
        firstName: 'Membership',
        lastName: 'Stack',
      );
      expect(joined.memberId, isNotNull);

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: 'filip.saric@stayfitjoyful.demo',
        password: 'Fitness123!',
      );
      final overviewBefore = _expectSuccess(await packages.getOverview());
      final member = overviewBefore.members.singleWhere(
        (item) => item.email == memberEmail,
      );
      expect(member.id, joined.memberId);
      expect(overviewBefore.activeMembershipFor(member.id), isNull);
      final plan = overviewBefore.plans.singleWhere(
        (item) => item.isActive && item.sessionLimit == 3,
      );
      final today = _today();
      _expectSuccess(
        await packages.assignPackage(
          MemberMembershipDraft(
            memberId: member.id,
            membershipPlanId: plan.id,
            startsOn: today.subtract(const Duration(days: 1)),
            endsOn: null,
          ),
        ),
      );

      final overviewAssigned = _expectSuccess(await packages.getOverview());
      final membership = overviewAssigned.activeMembershipFor(member.id);
      expect(membership, isNotNull);
      expect(membership!.membershipPlanId, plan.id);
      expect(membership.membershipPlanName, plan.name);

      final memberSession = await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: memberEmail,
        password: memberPassword,
      );
      expect(memberSession.user.memberId, member.id);
      final memberProfile = _expectSuccess(await profile.getProfile());
      expect(memberProfile.membership, isNotNull);
      expect(memberProfile.membership!.id, membership.id);
      expect(memberProfile.membership!.planName, plan.name);
      expect(memberProfile.membership!.isActive, isTrue);

      final futureSessions = _expectSuccess(await getSessions())
          .where(
            (session) =>
                session.status == 'scheduled' &&
                session.startsAt.isAfter(DateTime.now()),
          )
          .take(2)
          .toList(growable: false);
      expect(futureSessions, hasLength(2));
      final firstBooking = _expectSuccess(
        await createBooking(
          memberId: member.id,
          classSessionId: futureSessions.first.id,
        ),
      );
      expect(firstBooking.memberId, member.id);
      expect(firstBooking.classSessionId, futureSessions.first.id);
      expect(firstBooking.status, anyOf('booked', 'waitlisted'));

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: 'filip.saric@stayfitjoyful.demo',
        password: 'Fitness123!',
      );
      await payments.endMembership(membership.id, today);
      final overviewEnded = _expectSuccess(await packages.getOverview());
      final ended = overviewEnded.memberships.singleWhere(
        (item) => item.id == membership.id,
      );
      expect(ended.isActive, isFalse);
      expect(_dateOnly(ended.endsOn!), today);

      await _login(
        auth,
        tokenProvider,
        apiBaseUrl: apiBaseUrl,
        email: memberEmail,
        password: memberPassword,
      );
      final endedProfile = _expectSuccess(await profile.getProfile());
      expect(endedProfile.membership, isNull);
      _expectFailureStatus(
        await createBooking(
          memberId: member.id,
          classSessionId: futureSessions.last.id,
        ),
        409,
      );
    },
  );
}

Future<AuthSession> _login(
  AuthRemoteDataSource auth,
  _MutableAccessTokenProvider tokenProvider, {
  required String apiBaseUrl,
  required String email,
  required String password,
}) async {
  try {
    final account = await auth.login(email: email, password: password);
    tokenProvider.accessToken = account.accessToken;
    final studio = account.studios.singleWhere((item) => item.studioId == 1);
    final session = await auth.selectStudio(studio.studioId);
    tokenProvider.accessToken = session.accessToken;
    return session;
  } on ApiException catch (error) {
    throw TestFailure(
      'Could not log in as $email through $apiBaseUrl: ${error.message}',
    );
  }
}

T _expectSuccess<T>(Result<T> result) {
  return switch (result) {
    Success<T>(value: final value) => value,
    FailureResult<T>(failure: final failure) => throw TestFailure(
      'Expected a successful API result, but received: $failure',
    ),
  };
}

void _expectFailureStatus<T>(Result<T> result, int statusCode) {
  switch (result) {
    case Success():
      fail('Expected HTTP $statusCode, but the API call succeeded.');
    case FailureResult(failure: final failure):
      expect(failure.statusCode, statusCode);
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh membership-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
