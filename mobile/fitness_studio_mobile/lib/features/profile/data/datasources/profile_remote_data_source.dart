import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/api/profile');
    final data = response.data;

    if (data == null) {
      throw const FormatException('Profile response is empty.');
    }

    return ProfileModel.fromJson(data);
  }
}
