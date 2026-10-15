import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_exception.dart';
import '../domain/entities/class_type.dart';
import '../domain/repositories/class_types_repository.dart';
import 'class_type_model.dart';
import 'class_types_remote_data_source.dart';

class ClassTypesRepositoryImpl implements ClassTypesRepository {
  const ClassTypesRepositoryImpl(this._remote);

  final ClassTypesDataSource _remote;

  @override
  Future<Result<List<ClassType>>> getClassTypes() => _guard(() async {
    final values = await _remote.getClassTypes();
    return values
        .map((value) => ClassTypeModel.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  });

  @override
  Future<Result<ClassType>> createClassType(ClassTypeDraft draft) =>
      _guard(() async {
        final value = await _remote.createClassType(
          ClassTypeModel.draftToJson(draft),
        );
        return ClassTypeModel.fromJson(value);
      });

  @override
  Future<Result<void>> updateClassType(int id, ClassTypeDraft draft) =>
      _guard(() async {
        await _remote.updateClassType(id, ClassTypeModel.draftToJson(draft));
      });

  @override
  Future<Result<void>> deleteClassType(int id) => _guard(() async {
    await _remote.deleteClassType(id);
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
}
