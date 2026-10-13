import '../../../core/network/api_client.dart';

abstract class MembershipPlansDataSource {
  Future<List<dynamic>> getPlans();
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data);
  Future<void> updatePlan(int id, Map<String, dynamic> data);
  Future<void> deletePlan(int id);
}

class MembershipPlansRemoteDataSource implements MembershipPlansDataSource {
  const MembershipPlansRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<dynamic>> getPlans() async =>
      (await _api.get<List<dynamic>>('/api/membership-plans')).data ??
      <dynamic>[];

  @override
  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> data) async =>
      (await _api.post<Map<String, dynamic>>(
        '/api/membership-plans',
        data: data,
      )).data!;

  @override
  Future<void> updatePlan(int id, Map<String, dynamic> data) async {
    await _api.put<void>('/api/membership-plans/$id', data: data);
  }

  @override
  Future<void> deletePlan(int id) async {
    await _api.delete<void>('/api/membership-plans/$id');
  }
}
