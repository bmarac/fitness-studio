import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/entities/studio_membership.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/restore_session.dart';
import '../../data/services/auth_session_coordinator.dart';
import 'login_state.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  late final AuthRepository _repository;
  late final Login _login;
  late final Logout _logout;
  late final RestoreSession _restoreSession;

  @override
  LoginState build() {
    _repository = serviceLocator<AuthRepository>();
    _login = serviceLocator<Login>();
    _logout = serviceLocator<Logout>();
    _restoreSession = serviceLocator<RestoreSession>();
    if (serviceLocator.isRegistered<AuthSessionCoordinator>()) {
      final subscription = serviceLocator<AuthSessionCoordinator>().changes
          .listen(_applySessionChange);
      ref.onDispose(subscription.cancel);
    }
    Future.microtask(_restoreSavedSession);
    return const LoginChecking();
  }

  void _applySessionChange(AuthSessionChange change) {
    if (change.expired) {
      state = const LoginInitial(sessionExpired: true);
    } else if (change.studio case final session?) {
      state = LoginSuccess(session);
    } else if (change.account case final account?) {
      state = LoginAccountReady(account);
    }
  }

  Future<void> _restoreSavedSession() async {
    final studio = await _restoreSession();
    if (studio case Success(value: final session?)) {
      state = LoginSuccess(session);
      return;
    }
    final account = await _repository.restoreAccountSession();
    switch (account) {
      case Success(value: final session?):
        await _continueAccount(session);
      case Success():
        state = const LoginInitial();
      case FailureResult(failure: final failure):
        state = LoginError(failure);
    }
  }

  Future<void> login({required String email, required String password}) async {
    if (state is LoginLoading) return;
    state = const LoginLoading();
    final result = await _login(email: email, password: password);
    switch (result) {
      case Success(value: final session):
        await _continueAccount(session);
      case FailureResult(failure: final failure):
        state = LoginError(failure);
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    if (state is LoginLoading) return;
    state = const LoginLoading();
    final result = await _repository.register(email: email, password: password);
    switch (result) {
      case Success(value: final session):
        state = LoginAccountReady(session);
      case FailureResult(failure: final failure):
        state = LoginError(failure);
    }
  }

  Future<void> _continueAccount(AccountSession session) async {
    final lastStudioId = await _repository.readLastStudioId();
    final selected = preferredStudio(session.studios, lastStudioId);
    if (selected != null) {
      await selectStudio(selected.studioId, fallback: session);
    } else {
      state = LoginAccountReady(session);
    }
  }

  Future<void> selectStudio(int studioId, {AccountSession? fallback}) async {
    final account =
        fallback ??
        switch (state) {
          LoginAccountReady(session: final session) => session,
          _ => null,
        };
    state = const LoginLoading();
    final result = await _repository.selectStudio(studioId);
    state = switch (result) {
      Success(value: final session) => LoginSuccess(session),
      FailureResult() when account != null => LoginAccountReady(account),
      FailureResult(failure: final failure) => LoginError(failure),
    };
  }

  Future<Result<StudioLookup>> lookupStudio(String code) =>
      _repository.lookupStudio(code);

  Future<Failure?> joinStudio({
    required String code,
    String? firstName,
    String? lastName,
  }) async {
    final result = await _repository.joinStudio(
      code: code,
      firstName: firstName,
      lastName: lastName,
    );
    return switch (result) {
      Success(value: final membership) => _selectJoined(membership),
      FailureResult(failure: final failure) => failure,
    };
  }

  Future<Failure?> _selectJoined(StudioMembership membership) async {
    final result = await _repository.selectStudio(membership.studioId);
    switch (result) {
      case Success(value: final session):
        state = LoginSuccess(session);
        return null;
      case FailureResult(failure: final failure):
        return failure;
    }
  }

  Future<void> showStudioPicker() async {
    final result = await _repository.restoreAccountSession();
    state = switch (result) {
      Success(value: final session?) => LoginAccountReady(session),
      Success() => const LoginInitial(),
      FailureResult(failure: final failure) => LoginError(failure),
    };
  }

  Future<Failure?> logout() async {
    final result = await _logout();
    return switch (result) {
      Success() => _completeLogout(),
      FailureResult(failure: final failure) => failure,
    };
  }

  Failure? _completeLogout() {
    state = const LoginInitial();
    return null;
  }
}

StudioMembership? preferredStudio(
  List<StudioMembership> studios,
  int? lastStudioId,
) {
  for (final studio in studios) {
    if (studio.studioId == lastStudioId) return studio;
  }
  return studios.length == 1 ? studios.single : null;
}
