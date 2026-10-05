import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Result<Profile>> getProfile() async {
    try {
      return Success(await _remoteDataSource.getProfile());
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
    }
  }
}
