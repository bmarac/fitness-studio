import '../../../core/network/api_client.dart';

abstract class MemberPackagesDataSource {
  Future<List<dynamic>> getMembers();
  Future<List<dynamic>> getMemberships();
  Future<List<dynamic>> getPlans();
  Future<void> createMembership(Map<String, dynamic> data);
  Future<void> updateMembership(int id, Map<String, dynamic> data);
}

class MemberPackagesRemoteDataSource implements MemberPackagesDataSource {
  const MemberPackagesRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<dynamic>> getMembers() async =>
      (await _api.get<List<dynamic>>('/api/members')).data ?? <dynamic>[];

  @override
  Future<List<dynamic>> getMemberships() async =>
      (await _api.get<List<dynamic>>('/api/member-memberships')).data ??
      <dynamic>[];

  @override
  Future<List<dynamic>> getPlans() async =>
      (await _api.get<List<dynamic>>('/api/membership-plans')).data ??
      <dynamic>[];

  @override
  Future<void> createMembership(Map<String, dynamic> data) async {
    await _api.post<void>('/api/member-memberships', data: data);
  }

  @override
  Future<void> updateMembership(int id, Map<String, dynamic> data) async {
    await _api.put<void>('/api/member-memberships/$id', data: data);
  }
}
