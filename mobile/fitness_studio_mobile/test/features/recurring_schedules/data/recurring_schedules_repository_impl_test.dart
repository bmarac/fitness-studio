import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fitness_studio_mobile/core/auth/access_token_provider.dart';
import 'package:fitness_studio_mobile/core/config/app_config.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/core/network/api_client.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/datasources/recurring_schedules_remote_data_source.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/data/repositories/recurring_schedules_repository_impl.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/recurring_schedule_draft.dart';
import 'package:fitness_studio_mobile/features/recurring_schedules/domain/entities/schedule_form_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository maps data and sends recurring schedule commands', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test'));
    final adapter = _RecurringSchedulesAdapter();
    dio.httpClientAdapter = adapter;
    final repository = RecurringSchedulesRepositoryImpl(
      RecurringSchedulesRemoteDataSource(
        ApiClient(
          config: const AppConfig(apiBaseUrl: 'http://example.test'),
          accessTokenProvider: const _NoTokenProvider(),
          dio: dio,
        ),
      ),
    );

    final schedules = await repository.getSchedules();
    final members = await repository.getScheduleMembers(41);
    final memberOptions = await repository.getMemberOptions(
      41,
      DateTime(2026, 10, 20),
    );
    final form = await repository.getFormData();
    await repository.moveFixedScheduleMember(
      assignmentId: 91,
      targetScheduleId: 42,
    );
    await repository.addFixedScheduleMember(
      memberId: 22,
      scheduleId: 41,
      startsOn: DateTime(2026, 10, 20),
    );
    await repository.changeScheduleStatus(
      id: 41,
      action: 'pause',
      effectiveFrom: DateTime(2026, 10, 15),
    );
    await repository.createSchedule(
      RecurringScheduleDraft(
        classTypeId: 5,
        trainerId: 8,
        dayOfWeek: 2,
        startsAtTime: DateTime(2026, 1, 1, 9, 5),
        durationMinutes: 60,
        capacity: 12,
        validFrom: DateTime(2026, 10, 20),
      ),
    );
    final formData = (form as Success<ScheduleFormData>).value;

    expect((schedules as Success).value.single.id, 41);
    expect((members as Success).value.single.memberName, 'Iva Ivić');
    expect((memberOptions as Success).value.single.fullName, 'Mia Marić');
    expect(formData.classTypes.single.name, 'Pilates');
    expect(formData.trainers.single.fullName, 'Ana Horvat');
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      containsAll(<String>[
        'GET /api/recurring-class-schedules',
        'GET /api/recurring-class-schedules/41/members',
        'GET /api/class-types',
        'GET /api/trainers',
        'GET /api/recurring-class-schedules/41/available-members',
        'PATCH /api/member-fixed-schedules/91/move',
        'POST /api/member-fixed-schedules',
        'PATCH /api/recurring-class-schedules/41/pause',
        'POST /api/recurring-class-schedules',
      ]),
    );
    expect(
      adapter.request('PATCH', '/api/member-fixed-schedules/91/move').data,
      {'targetRecurringScheduleId': 42},
    );
    expect(
      adapter
          .request('GET', '/api/recurring-class-schedules/41/available-members')
          .queryParameters,
      {'startsOn': '2026-10-20'},
    );
    expect(adapter.request('POST', '/api/member-fixed-schedules').data, {
      'memberId': 22,
      'recurringScheduleId': 41,
      'startsOn': '2026-10-20',
      'endsOn': null,
      'status': 'active',
    });
    expect(
      adapter.request('PATCH', '/api/recurring-class-schedules/41/pause').data,
      {'effectiveFrom': '2026-10-15'},
    );
    expect(
      adapter.request('POST', '/api/recurring-class-schedules').data,
      containsPair('startsAtTime', '09:05:00'),
    );
  });
}

class _NoTokenProvider implements AccessTokenProvider {
  const _NoTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;
}

class _RecurringSchedulesAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  RequestOptions request(String method, String path) => requests.singleWhere(
    (request) => request.method == method && request.path == path,
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = switch (options.path) {
      '/api/recurring-class-schedules' when options.method == 'GET' => [
        {
          'id': 41,
          'classTypeName': 'Pilates',
          'trainerId': 8,
          'trainerName': 'Ana Horvat',
          'dayOfWeek': 2,
          'startsAtTime': '09:05:00',
          'durationMinutes': 60,
          'capacity': 12,
          'activeMemberCount': 1,
          'validFrom': '2026-10-20',
          'validUntil': null,
          'status': 'active',
          'statusEffectiveFrom': null,
        },
      ],
      '/api/recurring-class-schedules/41/members' => [
        {'id': 91, 'memberId': 21, 'memberName': 'Iva Ivić'},
      ],
      '/api/class-types' => [
        {
          'id': 5,
          'name': 'Pilates',
          'defaultDurationMinutes': 60,
          'defaultCapacity': 12,
        },
      ],
      '/api/trainers' => [
        {'id': 8, 'firstName': 'Ana', 'lastName': 'Horvat', 'status': 'active'},
      ],
      '/api/recurring-class-schedules/41/available-members' => [
        {
          'id': 22,
          'firstName': 'Mia',
          'lastName': 'Marić',
          'email': 'mia@example.com',
          'status': 'active',
        },
      ],
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
