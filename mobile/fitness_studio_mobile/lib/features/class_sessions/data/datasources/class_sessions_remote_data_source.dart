import '../../../../core/network/api_client.dart';
import '../models/class_session_model.dart';

class ClassSessionsRemoteDataSource {
  const ClassSessionsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ClassSessionModel>> getClassSessions() async {
    final response = await _apiClient.get<List<dynamic>>('/api/class-sessions');
    final data = response.data ?? [];

    return data
        .map((item) => ClassSessionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ClassSessionModel>> getMyClassSessions() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/class-sessions/mine',
    );
    final data = response.data ?? [];

    return data
        .map((item) => ClassSessionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ClassSessionModel> getClassSession(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/class-sessions/$id',
    );
    final data = response.data;

    if (data == null) {
      throw const FormatException('Class session response is empty.');
    }

    return ClassSessionModel.fromJson(data);
  }

  Future<void> cancelClassSession(int id) async {
    await _apiClient.patch<void>('/api/class-sessions/$id/cancel');
  }
}
