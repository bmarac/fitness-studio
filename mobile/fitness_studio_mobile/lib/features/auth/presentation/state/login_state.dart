import '../../../../core/error/failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/account_session.dart';

sealed class LoginState {
  const LoginState();
}

class LoginChecking extends LoginState {
  const LoginChecking();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess(this.session);

  final AuthSession session;
}

class LoginAccountReady extends LoginState {
  const LoginAccountReady(this.session);

  final AccountSession session;
}

class LoginError extends LoginState {
  const LoginError(this.failure);

  final Failure failure;
}
