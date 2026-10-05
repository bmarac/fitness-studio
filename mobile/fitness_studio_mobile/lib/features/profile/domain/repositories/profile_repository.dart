import '../../../../core/error/result.dart';
import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Result<Profile>> getProfile();
}
