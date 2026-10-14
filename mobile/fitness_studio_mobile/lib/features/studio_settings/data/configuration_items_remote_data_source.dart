import '../../../core/network/api_client.dart';

class ConfigurationItemsRemoteDataSource {
  const ConfigurationItemsRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<dynamic>> getClassTypes() async =>
      (await _api.get<List<dynamic>>('/api/class-types')).data ?? <dynamic>[];

  Future<List<dynamic>> saveClassTypes(Map<String, dynamic> data) async =>
      (await _api.put<List<dynamic>>(
        '/api/class-types/configuration',
        data: data,
      )).data ??
      <dynamic>[];
}
