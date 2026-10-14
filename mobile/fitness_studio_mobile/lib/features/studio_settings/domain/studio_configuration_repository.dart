import '../../../core/error/result.dart';
import 'configuration_items.dart';

abstract class StudioConfigurationRepository {
  Future<Result<List<ClassTypeConfiguration>>> getClassTypes();
  Future<Result<List<ClassTypeConfiguration>>> saveClassTypes(
    List<ClassTypeConfiguration> items,
    List<int> deletedIds,
  );
}
