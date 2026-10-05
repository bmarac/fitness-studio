import '../../../../core/error/result.dart';
import '../entities/class_session.dart';
import '../repositories/class_sessions_repository.dart';

class GetClassSession {
  const GetClassSession(this._repository);

  final ClassSessionsRepository _repository;

  Future<Result<ClassSession>> call(int id) {
    return _repository.getClassSession(id);
  }
}
