import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/account_session.dart';
import '../entities/studio_membership.dart';

abstract class AuthRepository {
  Future<Result<AuthSession?>> restoreSession();

  Future<Result<void>> logout();

  Future<Result<AccountSession>> login({
    required String email,
    required String password,
  });
  Future<Result<AccountSession>> register({
    required String email,
    required String password,
  });
  Future<Result<AccountSession?>> restoreAccountSession();
  Future<Result<AuthSession>> selectStudio(int studioId);
  Future<Result<StudioLookup>> lookupStudio(String code);
  Future<Result<StudioMembership>> joinStudio({
    required String code,
    String? firstName,
    String? lastName,
  });
  Future<int?> readLastStudioId();
}
