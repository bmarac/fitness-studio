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
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/get_bookings.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_sessions.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/datasources/recurring_schedules_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/repositories/recurring_schedules_repository_impl.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/fixed_schedule_member.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_fixed_schedule_members.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/get_recurring_schedules.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/usecases/move_fixed_schedule_member.dart';
import 'package:test/test.dart';

void main() {
  test('moving a fixed member schedule replaces future bookings', () async {
    final apiBaseUrl = _requiredEnvironmentValue(
      'FITNESS_STUDIO_TEST_API_BASE_URL',
    );
    final tokenProvider = _MutableAccessTokenProvider();
    final client = ApiClient(
      config: AppConfig(apiBaseUrl: apiBaseUrl),
      accessTokenProvider: tokenProvider,
    );
    final auth = AuthRemoteDataSource(client);
    final schedulesRepository = RecurringSchedulesRepositoryImpl(
      RecurringSchedulesRemoteDataSource(client),
    );
    final getSchedules = GetRecurringSchedules(schedulesRepository);
    final getMembers = GetFixedScheduleMembers(schedulesRepository);
    final moveMember = MoveFixedScheduleMember(schedulesRepository);
    final getSessions = GetClassSessions(
      ClassSessionsRepositoryImpl(ClassSessionsRemoteDataSource(client)),
    );
    final getBookings = GetBookings(
      BookingsRepositoryImpl(BookingsRemoteDataSource(client)),
    );

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'filip.saric@stayfitjoyful.demo',
    );
    final schedules = _expectSuccess(await getSchedules());
    final membersBySchedule = <int, List<FixedScheduleMember>>{};
    for (final schedule in schedules.where((item) => item.status == 'active')) {
      membersBySchedule[schedule.id] = _expectSuccess(
        await getMembers(schedule.id),
      );
    }

    const memberName = 'Ana Horvat';
    final source = schedules.firstWhere(
      (schedule) => membersBySchedule[schedule.id]!.any(
        (member) => member.memberName == memberName,
      ),
    );
    final sourceAssignment = membersBySchedule[source.id]!.singleWhere(
      (member) => member.memberName == memberName,
    );
    final target = _findTargetSchedule(
      schedules,
      membersBySchedule,
      source,
      memberName,
    );

    final sessions = _expectSuccess(await getSessions());
    final now = DateTime.now();
    final sourceSessionIds = sessions
        .where(
          (session) =>
              session.recurringScheduleId == source.id &&
              session.startsAt.isAfter(now),
        )
        .map((session) => session.id)
        .toSet();
    final targetSessionIds = sessions
        .where(
          (session) =>
              session.recurringScheduleId == target.id &&
              session.startsAt.isAfter(now),
        )
        .map((session) => session.id)
        .toSet();
    expect(sourceSessionIds, isNotEmpty);
    expect(targetSessionIds, isNotEmpty);

    final bookingsBefore = _expectSuccess(await getBookings());
    expect(
      bookingsBefore.where(
        (booking) =>
            booking.memberId == sourceAssignment.memberId &&
            sourceSessionIds.contains(booking.classSessionId) &&
            _isActive(booking.status),
      ),
      isNotEmpty,
    );

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'ana.horvat@stayfitjoyful.demo',
    );
    _expectFailureStatus(
      await moveMember(
        assignmentId: sourceAssignment.assignmentId,
        targetScheduleId: target.id,
      ),
      403,
    );

    await _login(
      auth,
      tokenProvider,
      apiBaseUrl: apiBaseUrl,
      email: 'filip.saric@stayfitjoyful.demo',
    );
    _expectSuccess(
      await moveMember(
        assignmentId: sourceAssignment.assignmentId,
        targetScheduleId: target.id,
      ),
    );

    final sourceMembersAfter = _expectSuccess(await getMembers(source.id));
    final targetMembersAfter = _expectSuccess(await getMembers(target.id));
    expect(
      sourceMembersAfter.any((member) => member.memberName == memberName),
      isFalse,
    );
    final targetAssignment = targetMembersAfter.singleWhere(
      (member) => member.memberName == memberName,
    );
    expect(targetAssignment.memberId, sourceAssignment.memberId);
    expect(targetAssignment.assignmentId, isNot(sourceAssignment.assignmentId));

    final bookingsAfter = _expectSuccess(await getBookings());
    final oldFutureBookings = bookingsAfter.where(
      (booking) =>
          booking.memberId == sourceAssignment.memberId &&
          sourceSessionIds.contains(booking.classSessionId),
    );
    expect(oldFutureBookings, isNotEmpty);
    expect(
      oldFutureBookings.every((booking) => booking.status == 'cancelled'),
      isTrue,
    );

    final targetFutureBookings = bookingsAfter.where(
      (booking) =>
          booking.memberId == sourceAssignment.memberId &&
          targetSessionIds.contains(booking.classSessionId) &&
          booking.bookingSource == 'fixed_schedule' &&
          _isActive(booking.status),
    );
    expect(targetFutureBookings, isNotEmpty);
  });
}

RecurringSchedule _findTargetSchedule(
  List<RecurringSchedule> schedules,
  Map<int, List<FixedScheduleMember>> membersBySchedule,
  RecurringSchedule source,
  String memberName,
) {
  return schedules.firstWhere(
    (schedule) =>
        schedule.status == 'active' &&
        schedule.id != source.id &&
        schedule.dayOfWeek == source.dayOfWeek &&
        schedule.startsAtTime != source.startsAtTime &&
        schedule.activeMemberCount < schedule.capacity &&
        !membersBySchedule[schedule.id]!.any(
          (member) => member.memberName == memberName,
        ),
  );
}

bool _isActive(String status) => status == 'booked' || status == 'waitlisted';

Future<AuthSession> _login(
  AuthRemoteDataSource auth,
  _MutableAccessTokenProvider tokenProvider, {
  required String apiBaseUrl,
  required String email,
}) async {
  try {
    final account = await auth.login(email: email, password: 'Fitness123!');
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

String _requiredEnvironmentValue(String name) {
  final value = Platform.environment[name];
  if (value == null || value.isEmpty) {
    throw StateError(
      '$name is required. Run this test through '
      './scripts/verify-fresh-stack.sh fixed-schedule-client.',
    );
  }
  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
