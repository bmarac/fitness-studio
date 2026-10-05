import '../../../../core/error/result.dart';
import '../repositories/class_sessions_repository.dart';

class CancelClassSession {
  const CancelClassSession(this._repository);

  final ClassSessionsRepository _repository;

  Future<Result<void>> call(int id) {
    return _repository.cancelClassSession(id);
  }
}
