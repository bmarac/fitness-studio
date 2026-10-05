import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';

abstract class AuthRepository {
  Future<Result<AuthSession?>> restoreSession();

  Future<Result<void>> logout();

  Future<Result<AuthSession>> login({
    required int studioId,
    required String email,
    required String password,
  });
}
