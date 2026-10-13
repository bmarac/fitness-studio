import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/bookings/data/datasources/bookings_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/bookings/data/repositories/bookings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingsRemoteDataSource', () {
    test('loads all bookings and filters by class session', () async {
      final adapter = _BookingsApiAdapter();
      final source = _source(adapter);

      final all = await source.getBookings();
      final bySession = await source.getBookingsByClassSessionId(21);

      expect(all.single.id, 31);
      expect(bySession.single.classSessionId, 21);
      expect(adapter.requests[0].path, '/api/bookings');
      expect(adapter.requests[0].queryParameters, isEmpty);
      expect(adapter.requests[1].path, '/api/bookings');
      expect(adapter.requests[1].queryParameters, {'classSessionId': 21});
    });

    test('loads member page with the exact paging query', () async {
      final adapter = _BookingsApiAdapter();
      final source = _source(adapter);

      final page = await source.getMemberBookingsPage(
        filter: 'history',
        page: 2,
        pageSize: 20,
      );

      expect(page.items.single.id, 31);
      expect(page.page, 2);
      expect(page.hasNextPage, isTrue);
      expect(adapter.requests.single.path, '/api/bookings/mine');
      expect(adapter.requests.single.queryParameters, {
        'filter': 'history',
        'page': 2,
        'pageSize': 20,
      });
    });

    test('sends cancellation and status mutations to exact routes', () async {
      final adapter = _BookingsApiAdapter();
      final source = _source(adapter);

      await source.cancelBooking(31);
      await source.updateBookingStatus(id: 31, status: 'attended');
      await source.cancelFixedSchedule(
        id: 7,
        effectiveFrom: DateTime(2026, 10, 13),
      );

      expect(
        adapter.requests.map((request) => '${request.method} ${request.path}'),
        [
          'DELETE /api/bookings/31',
          'PATCH /api/bookings/31/status',
          'PATCH /api/member-fixed-schedules/7/cancel',
        ],
      );
      expect(adapter.requests[1].data, {'status': 'attended'});
      expect(adapter.requests[2].data, {'effectiveFrom': '2026-10-13'});
    });

    test('creates a booking with member and session identifiers', () async {
      final adapter = _BookingsApiAdapter();
      final source = _source(adapter);

      final created = await source.createBooking(
        memberId: 10,
        classSessionId: 21,
      );

      expect(created.id, 31);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/api/bookings');
      expect(adapter.requests.single.data, {
        'memberId': 10,
        'classSessionId': 21,
      });
    });

    test('rejects empty page and create responses', () async {
      final adapter = _BookingsApiAdapter(returnNull: true);
      final source = _source(adapter);

      expect(
        () => source.getMemberBookingsPage(
          filter: 'upcoming',
          page: 1,
          pageSize: 20,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => source.createBooking(memberId: 10, classSessionId: 21),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('repository maps successful operations and response failures', () async {
    final successful = BookingsRepositoryImpl(_source(_BookingsApiAdapter()));
    final malformed = BookingsRepositoryImpl(
      _source(_BookingsApiAdapter(returnNull: true)),
    );

    expect(await successful.getBookings(), isA<Success>());
    expect(
      await successful.getMemberBookingsPage(
        filter: 'upcoming',
        page: 1,
        pageSize: 20,
      ),
      isA<Success>(),
    );
    expect(await successful.cancelBooking(31), isA<Success<void>>());
    expect(
      await successful.cancelFixedSchedule(
        id: 7,
        effectiveFrom: DateTime(2026, 10, 13),
      ),
      isA<Success<void>>(),
    );
    expect(
      await successful.updateBookingStatus(id: 31, status: 'attended'),
      isA<Success<void>>(),
    );
    expect(await successful.getBookingsByClassSessionId(21), isA<Success>());
    expect(
      await successful.createBooking(memberId: 10, classSessionId: 21),
      isA<Success>(),
    );

    final pageFailure = await malformed.getMemberBookingsPage(
      filter: 'upcoming',
      page: 1,
      pageSize: 20,
    );
    final createFailure = await malformed.createBooking(
      memberId: 10,
      classSessionId: 21,
    );
    expect(
      (pageFailure as FailureResult).failure.kind,
      FailureKind.readBookings,
    );
    expect((createFailure as FailureResult).failure.kind, FailureKind.readApi);
  });

  test('repository preserves API failures for every operation', () async {
    final repository = BookingsRepositoryImpl(
      _source(_BookingsApiAdapter(statusCode: 409)),
    );
    final results = <Result<Object?>>[
      await repository.getBookings(),
      await repository.getMemberBookingsPage(
        filter: 'upcoming',
        page: 1,
        pageSize: 20,
      ),
      await repository.cancelBooking(31),
      await repository.cancelFixedSchedule(
        id: 7,
        effectiveFrom: DateTime(2026, 10, 13),
      ),
      await repository.updateBookingStatus(id: 31, status: 'attended'),
      await repository.getBookingsByClassSessionId(21),
      await repository.createBooking(memberId: 10, classSessionId: 21),
    ];

    for (final result in results) {
      expect(result, isA<FailureResult>());
      expect((result as FailureResult).failure.statusCode, 409);
    }
  });
}

BookingsRemoteDataSource _source(_BookingsApiAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
  dio.httpClientAdapter = adapter;
  return BookingsRemoteDataSource(
    ApiClient(
      config: const AppConfig(apiBaseUrl: 'http://example.test'),
      accessTokenProvider: const _NoTokenProvider(),
      dio: dio,
    ),
  );
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _BookingsApiAdapter implements HttpClientAdapter {
  _BookingsApiAdapter({this.returnNull = false, this.statusCode = 200});

  final bool returnNull;
  final int statusCode;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object? body = returnNull
        ? null
        : switch ((options.method, options.path)) {
            ('GET', '/api/bookings/mine') => {
              'items': [_bookingJson],
              'page': 2,
              'pageSize': 20,
              'hasNextPage': true,
            },
            ('GET', '/api/bookings') => [_bookingJson],
            ('POST', '/api/bookings') => _bookingJson,
            _ => const <String, dynamic>{},
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _bookingJson = <String, dynamic>{
  'id': 31,
  'memberId': 10,
  'memberFirstName': 'Ana',
  'memberLastName': 'Horvat',
  'classSessionId': 21,
  'bookingSource': 'self_service',
  'memberFixedScheduleId': null,
  'classTypeId': 5,
  'classTypeName': 'Pilates',
  'trainerId': 8,
  'trainerFirstName': 'Filip',
  'trainerLastName': 'Šarić',
  'classSessionStartsAt': '2030-10-13T17:00:00Z',
  'classSessionEndsAt': '2030-10-13T18:00:00Z',
  'status': 'booked',
  'bookedAt': '2030-10-12T12:00:00Z',
  'cancelledAt': null,
  'attendedAt': null,
};
