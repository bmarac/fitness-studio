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
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/cancel_booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/create_booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/get_bookings.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/datasources/class_sessions_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/class_sessions/data/repositories/class_sessions_repository_impl.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/usecases/get_class_sessions.dart';
import 'package:test/test.dart';

void main() {
  test(
    'member cancels and replaces a booking through the live stack',
    () async {
      final apiBaseUrl = _requiredEnvironmentValue(
        'FITNESS_STUDIO_TEST_API_BASE_URL',
      );
      final email =
          Platform.environment['FITNESS_STUDIO_TEST_EMAIL'] ??
          'ana.horvat@stayfitjoyful.demo';
      final password =
          Platform.environment['FITNESS_STUDIO_TEST_PASSWORD'] ?? 'Fitness123!';
      final tokenProvider = _MutableAccessTokenProvider();
      final apiClient = ApiClient(
        config: AppConfig(apiBaseUrl: apiBaseUrl),
        accessTokenProvider: tokenProvider,
      );

      final authSession = await _login(
        AuthRemoteDataSource(apiClient),
        apiBaseUrl: apiBaseUrl,
        email: email,
        password: password,
      );

      expect(authSession.accessToken, isNotEmpty);
      expect(authSession.user.email, email);
      expect(authSession.user.studioId, 1);
      expect(authSession.user.memberId, isNotNull);
      expect(authSession.user.roles, contains('member'));
      tokenProvider.accessToken = authSession.accessToken;

      final bookingsRepository = BookingsRepositoryImpl(
        BookingsRemoteDataSource(apiClient),
      );
      final getBookings = GetBookings(bookingsRepository);
      final cancelBooking = CancelBooking(bookingsRepository);
      final createBooking = CreateBooking(bookingsRepository);
      final classSessionsRepository = ClassSessionsRepositoryImpl(
        ClassSessionsRemoteDataSource(apiClient),
      );
      final getClassSession = GetClassSession(classSessionsRepository);
      final getClassSessions = GetClassSessions(classSessionsRepository);

      final bookingsBefore = _expectSuccess(await getBookings());
      final cancellableBookings = bookingsBefore.where(
        (booking) => booking.canMemberCancel(DateTime.now()),
      );
      expect(
        cancellableBookings,
        isNotEmpty,
        reason: 'The fresh demo database must contain a cancellable booking.',
      );
      final booking = cancellableBookings.first;

      final classSession = _expectSuccess(
        await getClassSession(booking.classSessionId),
      );
      expect(classSession.id, booking.classSessionId);
      expect(classSession.classTypeId, booking.classTypeId);
      expect(
        classSession.startsAt.toUtc(),
        booking.classSessionStartsAt.toUtc(),
      );

      _expectSuccess(await cancelBooking(booking.id));

      final bookingsAfter = _expectSuccess(await getBookings());
      final cancelledBooking = bookingsAfter.singleWhere(
        (candidate) => candidate.id == booking.id,
      );
      expect(cancelledBooking.status, 'cancelled');
      expect(cancelledBooking.cancelledAt, isNotNull);

      final classSessions = _expectSuccess(await getClassSessions());
      final replacementCandidates = classSessions.where(
        (candidate) =>
            candidate.status == 'scheduled' &&
            candidate.id != classSession.id &&
            _isSameLocalDate(candidate.startsAt, classSession.startsAt),
      );
      expect(
        replacementCandidates,
        isNotEmpty,
        reason: 'The fresh demo database must contain a replacement session.',
      );
      final replacementSession = replacementCandidates.first;
      final replacementBooking = _expectSuccess(
        await createBooking(
          memberId: authSession.user.memberId!,
          classSessionId: replacementSession.id,
        ),
      );
      expect(replacementBooking.classSessionId, replacementSession.id);
      expect(replacementBooking.status, 'booked');

      final finalBookings = _expectSuccess(await getBookings());
      final persistedReplacement = finalBookings.singleWhere(
        (candidate) => candidate.id == replacementBooking.id,
      );
      expect(persistedReplacement.memberId, authSession.user.memberId);
      expect(persistedReplacement.classSessionId, replacementSession.id);
      expect(persistedReplacement.status, 'booked');

      final limitCandidates = classSessions.where(
        (candidate) =>
            candidate.status == 'scheduled' &&
            candidate.id != classSession.id &&
            candidate.id != replacementSession.id &&
            _isSameLocalDate(candidate.startsAt, classSession.startsAt),
      );
      expect(
        limitCandidates,
        isNotEmpty,
        reason: 'The fresh demo database must contain a membership-limit case.',
      );
      final limitResult = await createBooking(
        memberId: authSession.user.memberId!,
        classSessionId: limitCandidates.first.id,
      );
      _expectFailureStatus(limitResult, 409);
    },
  );
}

bool _isSameLocalDate(DateTime first, DateTime second) {
  final firstLocal = first.toLocal();
  final secondLocal = second.toLocal();
  return firstLocal.year == secondLocal.year &&
      firstLocal.month == secondLocal.month &&
      firstLocal.day == secondLocal.day;
}

Future<AuthSession> _login(
  AuthRemoteDataSource dataSource, {
  required String apiBaseUrl,
  required String email,
  required String password,
}) async {
  try {
    final account = await dataSource.login(email: email, password: password);
    final studio = account.studios.singleWhere((item) => item.studioId == 1);
    return await dataSource.selectStudio(studio.studioId);
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
      './scripts/verify-fresh-stack.sh booking-client.',
    );
  }

  return value;
}

class _MutableAccessTokenProvider implements AccessTokenProvider {
  String? accessToken;

  @override
  Future<String?> getAccessToken() async => accessToken;
}
