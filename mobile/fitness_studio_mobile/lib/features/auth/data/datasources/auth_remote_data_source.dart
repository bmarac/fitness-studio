import '../../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthSessionModel> login({
    required int studioId,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'studioId': studioId, 'email': email, 'password': password},
    );
    final data = response.data;

    if (data == null) {
      throw const FormatException('Login response is empty.');
    }

    return AuthSessionModel.fromJson(data);
  }
}
