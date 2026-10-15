import '../../../../core/error/result.dart';
import '../entities/class_type.dart';

abstract class ClassTypesRepository {
  Future<Result<List<ClassType>>> getClassTypes();
  Future<Result<ClassType>> createClassType(ClassTypeDraft draft);
  Future<Result<void>> updateClassType(int id, ClassTypeDraft draft);
  Future<Result<void>> deleteClassType(int id);
}
