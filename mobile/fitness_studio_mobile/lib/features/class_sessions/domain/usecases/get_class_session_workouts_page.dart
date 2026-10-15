import '../../../../core/error/result.dart';
import '../entities/class_session_workouts_page.dart';
import '../repositories/class_sessions_repository.dart';

class GetClassSessionWorkoutsPage {
  const GetClassSessionWorkoutsPage(this._repository);

  final ClassSessionsRepository _repository;

  Future<Result<ClassSessionWorkoutsPage>> call({
    required String filter,
    required int page,
    required int pageSize,
    int? trainerId,
  }) {
    return _repository.getWorkoutClassSessions(
      filter: filter,
      page: page,
      pageSize: pageSize,
      trainerId: trainerId,
    );
  }
}
