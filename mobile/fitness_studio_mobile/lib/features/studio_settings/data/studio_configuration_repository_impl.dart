import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_exception.dart';
import '../domain/configuration_items.dart';
import '../domain/studio_configuration_repository.dart';
import 'configuration_items_remote_data_source.dart';

class StudioConfigurationRepositoryImpl
    implements StudioConfigurationRepository {
  const StudioConfigurationRepositoryImpl(this._remote);

  final ConfigurationItemsRemoteDataSource _remote;

  @override
  Future<Result<List<ClassTypeConfiguration>>> getClassTypes() =>
      _guard(() async => _classTypes(await _remote.getClassTypes()));

  @override
  Future<Result<List<ClassTypeConfiguration>>> saveClassTypes(
    List<ClassTypeConfiguration> items,
    List<int> deletedIds,
  ) => _guard(
    () async => _classTypes(
      await _remote.saveClassTypes({
        'items': items.map(_classTypeJson).toList(growable: false),
        'deletedIds': deletedIds,
      }),
    ),
  );

  List<ClassTypeConfiguration> _classTypes(List<dynamic> values) => values
      .map((value) => value as Map<String, dynamic>)
      .map(
        (json) => ClassTypeConfiguration(
          id: (json['id'] as num).toInt(),
          name: json['name'] as String,
          description: json['description'] as String?,
          defaultDurationMinutes: (json['defaultDurationMinutes'] as num)
              .toInt(),
          defaultCapacity: (json['defaultCapacity'] as num).toInt(),
          difficultyLevel: json['difficultyLevel'] as String,
          status: json['status'] as String,
        ),
      )
      .toList(growable: false);

  Map<String, dynamic> _classTypeJson(ClassTypeConfiguration item) => {
    'id': item.id,
    'name': item.name.trim(),
    'description': _optional(item.description),
    'defaultDurationMinutes': item.defaultDurationMinutes,
    'defaultCapacity': item.defaultCapacity,
    'difficultyLevel': item.difficultyLevel,
    'status': item.status,
  };

  String? _optional(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

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
