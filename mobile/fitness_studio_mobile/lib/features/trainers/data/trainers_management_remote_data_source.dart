import '../../../core/network/api_client.dart';

class TrainersManagementRemoteDataSource {
  const TrainersManagementRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<dynamic>> getTrainers() async =>
      (await _api.get<List<dynamic>>('/api/trainers')).data ?? <dynamic>[];

  Future<Map<String, dynamic>> createTrainer(Map<String, dynamic> data) async =>
      (await _api.post<Map<String, dynamic>>(
        '/api/trainers',
        data: data,
      )).data!;
}
