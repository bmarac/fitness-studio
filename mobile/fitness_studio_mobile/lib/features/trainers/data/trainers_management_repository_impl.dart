import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_exception.dart';
import '../domain/entities/trainer_management.dart';
import '../domain/repositories/trainers_management_repository.dart';
import 'trainers_management_remote_data_source.dart';

class TrainersManagementRepositoryImpl implements TrainersManagementRepository {
  const TrainersManagementRepositoryImpl(this._remote);

  final TrainersManagementDataSource _remote;

  @override
  Future<Result<List<TrainerSummary>>> getTrainers() => _guard(() async {
    final values = await _remote.getTrainers();
    return values
        .map((value) => _trainer(value as Map<String, dynamic>))
        .toList(growable: false);
  });

  @override
  Future<Result<TrainerSummary>> createTrainer(TrainerDraft draft) =>
      _guard(() async {
        final value = await _remote.createTrainer(_draftToJson(draft));
        return _trainer(value);
      });

  @override
  Future<Result<void>> updateTrainer(int id, TrainerDraft draft) =>
      _guard(() async {
        await _remote.updateTrainer(id, _draftToJson(draft));
      });

  @override
  Future<Result<void>> deleteTrainer(int id) => _guard(() async {
    await _remote.deleteTrainer(id);
  });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    } on TypeError {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  static TrainerSummary _trainer(Map<String, dynamic> json) => TrainerSummary(
    id: json['id'] as int,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    bio: json['bio'] as String?,
    status: json['status'] as String,
  );

  static Map<String, dynamic> _draftToJson(TrainerDraft draft) => {
    'firstName': draft.firstName.trim(),
    'lastName': draft.lastName.trim(),
    'email': draft.email.trim().toLowerCase(),
    'phone': _optional(draft.phone),
    'bio': _optional(draft.bio),
    'status': draft.status,
  };

  static String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}
