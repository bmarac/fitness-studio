import '../../../../core/error/result.dart';
import '../entities/class_session.dart';
import '../entities/class_session_workouts_page.dart';

abstract class ClassSessionsRepository {
  Future<Result<List<ClassSession>>> getClassSessions({
    DateTime? from,
    DateTime? to,
  });

  Future<Result<List<ClassSession>>> getMyClassSessions();

  Future<Result<ClassSessionWorkoutsPage>> getWorkoutClassSessions({
    required String filter,
    required int page,
    required int pageSize,
    int? trainerId,
  });

  Future<Result<ClassSession>> getClassSession(int id);

  Future<Result<void>> cancelClassSession(int id);
}
