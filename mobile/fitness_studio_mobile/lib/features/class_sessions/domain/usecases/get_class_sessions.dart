import '../../../../core/error/result.dart';
import '../entities/class_session.dart';
import '../repositories/class_sessions_repository.dart';

class GetClassSessions {
  const GetClassSessions(this._repository);

  final ClassSessionsRepository _repository;

  Future<Result<List<ClassSession>>> call() {
    return _repository.getClassSessions();
  }
}
