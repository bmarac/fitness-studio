import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/account_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/auth_session.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/authenticated_user.dart';
import 'package:fitness_studio_mobile/features/auth/domain/entities/studio_membership.dart';
import 'package:fitness_studio_mobile/features/auth/domain/repositories/auth_repository.dart';

const testStudio = StudioMembership(
  studioId: 7,
  studioName: 'Stay Fit',
  memberId: 11,
  trainerId: null,
  roles: ['member'],
);

const otherTestStudio = StudioMembership(
  studioId: 8,
  studioName: 'Second Studio',
  memberId: null,
  trainerId: 12,
  roles: ['trainer'],
);

final testAccount = AccountSession(
  accessToken: 'account-token',
  expiresAt: DateTime.utc(2030),
  userId: 42,
  email: 'member@example.com',
  studios: const [testStudio],
);

final testAuthSession = AuthSession(
  accessToken: 'studio-token',
  expiresAt: DateTime.utc(2030),
  user: const AuthenticatedUser(
    id: 42,
    studioId: 7,
    memberId: 11,
    trainerId: null,
    email: 'member@example.com',
    roles: ['member'],
  ),
);

class FakeAuthRepository implements AuthRepository {
  Result<AuthSession?> restoreSessionResult = const Success(null);
  Result<AccountSession?> restoreAccountResult = const Success(null);
  Result<AccountSession> loginResult = Success(testAccount);
  Result<AccountSession> registerResult = Success(testAccount);
  Result<AuthSession> selectResult = Success(testAuthSession);
  Result<StudioLookup> lookupResult = const Success(
    StudioLookup(
      studioId: 7,
      studioName: 'Stay Fit',
      requiresProfileDetails: true,
      role: 'member',
    ),
  );
  Result<StudioMembership> joinResult = const Success(testStudio);
  Result<void> logoutResult = const Success(null);
  int? lastStudioId;
  int? selectedStudioId;
  String? lookupCode;
  ({String code, String? firstName, String? lastName})? joinArguments;

  @override
  Future<Result<AccountSession>> login({
    required String email,
    required String password,
  }) async => loginResult;

  @override
  Future<Result<AccountSession>> register({
    required String email,
    required String password,
  }) async => registerResult;

  @override
  Future<Result<AuthSession?>> restoreSession() async => restoreSessionResult;

  @override
  Future<Result<AccountSession?>> restoreAccountSession() async =>
      restoreAccountResult;

  @override
  Future<int?> readLastStudioId() async => lastStudioId;

  @override
  Future<Result<AuthSession>> selectStudio(int studioId) async {
    selectedStudioId = studioId;
    return selectResult;
  }

  @override
  Future<Result<StudioLookup>> lookupStudio(String code) async {
    lookupCode = code;
    return lookupResult;
  }

  @override
  Future<Result<StudioMembership>> joinStudio({
    required String code,
    String? firstName,
    String? lastName,
  }) async {
    joinArguments = (code: code, firstName: firstName, lastName: lastName);
    return joinResult;
  }

  @override
  Future<Result<void>> logout() async => logoutResult;
}
