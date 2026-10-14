import '../../../../core/network/api_client.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../models/class_type_option_model.dart';
import '../models/trainer_option_model.dart';
import '../models/recurring_schedule_model.dart';
import '../models/fixed_schedule_member_model.dart';
import '../../domain/entities/schedule_member_option.dart';

class RecurringSchedulesRemoteDataSource {
  const RecurringSchedulesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RecurringScheduleModel>> getSchedules() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/recurring-class-schedules',
    );

    return (response.data ?? [])
        .map(
          (item) =>
              RecurringScheduleModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> changeScheduleStatus({
    required int id,
    required String action,
    required DateTime effectiveFrom,
  }) async {
    await _apiClient.patch<void>(
      '/api/recurring-class-schedules/$id/$action',
      data: {'effectiveFrom': _formatDate(effectiveFrom)},
    );
  }

  Future<List<FixedScheduleMemberModel>> getScheduleMembers(
    int scheduleId,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/recurring-class-schedules/$scheduleId/members',
    );

    return (response.data ?? [])
        .map(
          (item) =>
              FixedScheduleMemberModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<ScheduleMemberOption>> getMemberOptions(
    int scheduleId,
    DateTime startsOn,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/recurring-class-schedules/$scheduleId/available-members',
      queryParameters: {'startsOn': _formatDate(startsOn)},
    );

    return (response.data ?? [])
        .map((item) {
          final json = item as Map<String, dynamic>;
          return ScheduleMemberOption(
            id: (json['id'] as num).toInt(),
            firstName: json['firstName'] as String,
            lastName: json['lastName'] as String,
            email: json['email'] as String,
            status: json['status'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<void> addFixedScheduleMember({
    required int memberId,
    required int scheduleId,
    required DateTime startsOn,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/member-fixed-schedules',
      data: {
        'memberId': memberId,
        'recurringScheduleId': scheduleId,
        'startsOn': _formatDate(startsOn),
        'endsOn': null,
        'status': 'active',
      },
    );
  }

  Future<void> moveFixedScheduleMember({
    required int assignmentId,
    required int targetScheduleId,
  }) async {
    await _apiClient.patch<void>(
      '/api/member-fixed-schedules/$assignmentId/move',
      data: {'targetRecurringScheduleId': targetScheduleId},
    );
  }

  Future<List<ClassTypeOptionModel>> getClassTypes() async {
    final response = await _apiClient.get<List<dynamic>>('/api/class-types');

    return (response.data ?? [])
        .map(
          (item) => ClassTypeOptionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<TrainerOptionModel>> getTrainers() async {
    final response = await _apiClient.get<List<dynamic>>('/api/trainers');

    return (response.data ?? [])
        .map(
          (item) => TrainerOptionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> createSchedule(RecurringScheduleDraft draft) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/recurring-class-schedules',
      data: {
        'classTypeId': draft.classTypeId,
        'trainerId': draft.trainerId,
        'dayOfWeek': draft.dayOfWeek,
        'startsAtTime': _formatTime(draft.startsAtTime),
        'durationMinutes': draft.durationMinutes,
        'capacity': draft.capacity,
        'validFrom': _formatDate(draft.validFrom),
        'validUntil': null,
        'status': 'active',
      },
    );
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
