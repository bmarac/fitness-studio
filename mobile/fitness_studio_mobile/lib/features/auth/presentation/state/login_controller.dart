import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/restore_session.dart';
import 'login_state.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  late final AppConfig _config;
  late final Login _login;
  late final Logout _logout;
  late final RestoreSession _restoreSession;

  @override
  LoginState build() {
    _config = serviceLocator<AppConfig>();
    _login = serviceLocator<Login>();
    _logout = serviceLocator<Logout>();
    _restoreSession = serviceLocator<RestoreSession>();
    Future.microtask(_restoreSavedSession);
    return const LoginChecking();
  }

  Future<void> _restoreSavedSession() async {
    final result = await _restoreSession();

    state = switch (result) {
      Success(value: final session) when session != null => LoginSuccess(
        session,
      ),
      Success() => const LoginInitial(),
      FailureResult(failure: final failure) => LoginError(failure.message),
    };
  }

  Future<void> login({required String email, required String password}) async {
    if (state is LoginLoading) {
      return;
    }

    state = const LoginLoading();
    final result = await _login(
      studioId: _config.currentStudioId,
      email: email,
      password: password,
    );

    state = switch (result) {
      Success(value: final session) => LoginSuccess(session),
      FailureResult(failure: final failure) => LoginError(failure.message),
    };
  }

  Future<String?> logout() async {
    final result = await _logout();

    return switch (result) {
      Success() => _completeLogout(),
      FailureResult(failure: final failure) => failure.message,
    };
  }

  String? _completeLogout() {
    state = const LoginInitial();
    return null;
  }
}
