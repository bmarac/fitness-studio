import '../../../../core/error/result.dart';
import '../entities/class_session.dart';

abstract class ClassSessionsRepository {
  Future<Result<List<ClassSession>>> getClassSessions();

  Future<Result<List<ClassSession>>> getMyClassSessions();

  Future<Result<ClassSession>> getClassSession(int id);

  Future<Result<void>> cancelClassSession(int id);
}
