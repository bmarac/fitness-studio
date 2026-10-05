import '../../domain/entities/auth_session.dart';

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

class LoginError extends LoginState {
  const LoginError(this.message);

  final String message;
}
