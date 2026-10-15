import '../../../core/network/api_client.dart';

abstract class TrainersManagementDataSource {
  Future<List<dynamic>> getTrainers();
  Future<Map<String, dynamic>> createTrainer(Map<String, dynamic> data);
  Future<void> updateTrainer(int id, Map<String, dynamic> data);
  Future<void> deleteTrainer(int id);
}

class TrainersManagementRemoteDataSource
    implements TrainersManagementDataSource {
  const TrainersManagementRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<dynamic>> getTrainers() async =>
      (await _api.get<List<dynamic>>('/api/trainers')).data ?? <dynamic>[];

  @override
  Future<Map<String, dynamic>> createTrainer(Map<String, dynamic> data) async =>
      (await _api.post<Map<String, dynamic>>(
        '/api/trainers',
        data: data,
      )).data!;

  @override
  Future<void> updateTrainer(int id, Map<String, dynamic> data) async {
    await _api.put<void>('/api/trainers/$id', data: data);
  }

  @override
  Future<void> deleteTrainer(int id) async {
    await _api.delete<void>('/api/trainers/$id');
  }
}
