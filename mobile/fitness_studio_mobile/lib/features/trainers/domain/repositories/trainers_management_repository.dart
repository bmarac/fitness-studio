import '../../../../core/error/result.dart';
import '../entities/trainer_management.dart';

abstract class TrainersManagementRepository {
  Future<Result<List<TrainerSummary>>> getTrainers();
  Future<Result<TrainerSummary>> createTrainer(TrainerDraft draft);
  Future<Result<void>> updateTrainer(int id, TrainerDraft draft);
  Future<Result<void>> deleteTrainer(int id);
}
