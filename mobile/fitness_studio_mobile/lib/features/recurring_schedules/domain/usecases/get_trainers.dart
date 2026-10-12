import '../../../../core/error/result.dart';
import '../entities/trainer_option.dart';
import '../repositories/recurring_schedules_repository.dart';

class GetTrainers {
  const GetTrainers(this._repository);

  final RecurringSchedulesRepository _repository;

  Future<Result<List<TrainerOption>>> call() => _repository.getTrainers();
}
