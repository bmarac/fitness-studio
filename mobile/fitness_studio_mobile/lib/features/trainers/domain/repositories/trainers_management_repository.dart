import '../../../../core/error/result.dart';
import '../entities/trainer_management.dart';

abstract class TrainersManagementRepository {
  Future<Result<List<TrainerSummary>>> getTrainers();
  Future<Result<TrainerSummary>> createTrainer(TrainerDraft draft);
}
