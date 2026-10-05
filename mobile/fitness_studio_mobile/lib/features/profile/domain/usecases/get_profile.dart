import '../../../../core/error/result.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this._repository);

  final ProfileRepository _repository;

  Future<Result<Profile>> call() => _repository.getProfile();
}
