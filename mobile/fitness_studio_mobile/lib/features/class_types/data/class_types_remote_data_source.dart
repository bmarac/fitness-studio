import '../../../core/network/api_client.dart';

abstract class ClassTypesDataSource {
  Future<List<dynamic>> getClassTypes();
  Future<Map<String, dynamic>> createClassType(Map<String, dynamic> data);
  Future<void> updateClassType(int id, Map<String, dynamic> data);
  Future<void> deleteClassType(int id);
}

class ClassTypesRemoteDataSource implements ClassTypesDataSource {
  const ClassTypesRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<dynamic>> getClassTypes() async =>
      (await _api.get<List<dynamic>>('/api/class-types')).data ?? <dynamic>[];

  @override
  Future<Map<String, dynamic>> createClassType(
    Map<String, dynamic> data,
  ) async => (await _api.post<Map<String, dynamic>>(
    '/api/class-types',
    data: data,
  )).data!;

  @override
  Future<void> updateClassType(int id, Map<String, dynamic> data) async {
    await _api.put<void>('/api/class-types/$id', data: data);
  }

  @override
  Future<void> deleteClassType(int id) async {
    await _api.delete<void>('/api/class-types/$id');
  }
}
