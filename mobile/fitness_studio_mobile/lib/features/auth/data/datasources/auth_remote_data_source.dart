import '../../../../core/network/api_client.dart';
import '../../domain/entities/studio_membership.dart';
import '../models/account_session_model.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);
  final ApiClient _api;

  Future<AccountSessionModel> login({
    required String email,
    required String password,
  }) => _account('/api/auth/login', email, password);

  Future<AccountSessionModel> register({
    required String email,
    required String password,
  }) => _account('/api/auth/register', email, password);

  Future<AccountSessionModel> _account(
    String path,
    String email,
    String password,
  ) async {
    final response = await _api.post<Map<String, dynamic>>(
      path,
      data: {'email': email, 'password': password},
    );
    if (response.data == null) {
      throw const FormatException('Account response is empty.');
    }
    return AccountSessionModel.fromJson(response.data!);
  }

  Future<AuthSessionModel> selectStudio(int studioId) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/account/studios/$studioId/select',
    );
    if (response.data == null) {
      throw const FormatException('Studio session is empty.');
    }
    return AuthSessionModel.fromJson(response.data!);
  }

  Future<StudioLookup> lookupStudio(String code) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/account/studios/lookup',
      data: {'code': code},
    );
    final json = response.data;
    if (json == null) throw const FormatException('Studio lookup is empty.');
    return StudioLookup(
      studioId: json['studioId'] as int,
      studioName: json['studioName'] as String,
      requiresProfileDetails: json['requiresProfileDetails'] as bool,
      role: json['role'] as String,
    );
  }

  Future<StudioMembershipModel> joinStudio({
    required String code,
    String? firstName,
    String? lastName,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/api/account/studios/join',
      data: {'code': code, 'firstName': ?firstName, 'lastName': ?lastName},
    );
    if (response.data == null) {
      throw const FormatException('Studio join is empty.');
    }
    return StudioMembershipModel.fromJson(response.data!);
  }
}
