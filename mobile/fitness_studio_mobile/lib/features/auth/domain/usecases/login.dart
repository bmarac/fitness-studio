import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required int studioId,
    required String email,
    required String password,
  }) {
    return _repository.login(
      studioId: studioId,
      email: email,
      password: password,
    );
  }
}
