import '../../../../core/error/result.dart';
import '../entities/class_session.dart';
import '../repositories/class_sessions_repository.dart';

class GetMyClassSessions {
  const GetMyClassSessions(this._repository);

  final ClassSessionsRepository _repository;

  Future<Result<List<ClassSession>>> call() {
    return _repository.getMyClassSessions();
  }
}
