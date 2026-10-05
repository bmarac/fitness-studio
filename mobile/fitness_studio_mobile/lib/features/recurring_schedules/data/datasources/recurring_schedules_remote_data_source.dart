import '../../../../core/network/api_client.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../models/class_type_option_model.dart';
import '../models/trainer_option_model.dart';

class RecurringSchedulesRemoteDataSource {
  const RecurringSchedulesRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

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
