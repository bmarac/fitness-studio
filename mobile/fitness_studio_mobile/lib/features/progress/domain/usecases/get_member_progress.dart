import '../../../../core/error/result.dart';
import '../entities/member_progress.dart';
import '../repositories/progress_repository.dart';

class GetMemberProgress {
  const GetMemberProgress(this._repository);

  final ProgressRepository _repository;

  Future<Result<MemberProgress>> call(int memberId) {
    return _repository.getMemberProgress(memberId);
  }
}
