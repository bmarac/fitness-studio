import '../../../../core/network/api_client.dart';
import '../models/member_progress_model.dart';
import '../../domain/entities/progress_management.dart';

class ProgressRemoteDataSource {
  const ProgressRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<MemberProgressModel> getMemberProgress(int memberId) async {
    final responses = await Future.wait([
      _apiClient.get<Map<String, dynamic>>(
        '/api/members/$memberId/measurements/latest',
      ),
      _apiClient.get<List<dynamic>>('/api/members/$memberId/measurements'),
    ]);
    final latest = responses[0].data;
    final history = responses[1].data;

    if (latest is! Map<String, dynamic> || history is! List<dynamic>) {
      throw const FormatException('Progress response is incomplete.');
    }

    return MemberProgressModel.fromJson(
      latestJson: latest,
      historyJson: history,
    );
  }

  Future<List<ProgressMember>> getMembers() async {
    final response = await _apiClient.get<List<dynamic>>('/api/members');
    final data = response.data;
    if (data == null) throw const FormatException('Members response is empty.');

    return data
        .map((item) {
          final json = item as Map<String, dynamic>;
          return ProgressMember(
            id: (json['id'] as num).toInt(),
            firstName: json['firstName'] as String,
            lastName: json['lastName'] as String,
            email: json['email'] as String,
            status: json['status'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<List<MeasurementParameter>> getMeasurementParameters() async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/measurement-parameters',
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Measurement parameters response is empty.');
    }

    return data
        .map((item) {
          final json = item as Map<String, dynamic>;
          return MeasurementParameter(
            id: (json['id'] as num).toInt(),
            code: json['code'] as String,
            name: json['name'] as String,
            unit: json['unit'] as String?,
            sortOrder: (json['sortOrder'] as num).toInt(),
            status: json['status'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<List<MeasurementParameter>> saveMeasurementParameters(
    List<MeasurementParameter> parameters,
  ) async {
    final response = await _apiClient.put<List<dynamic>>(
      '/api/measurement-parameters/configuration',
      data: {
        'items': [
          for (var index = 0; index < parameters.length; index++)
            {
              'id': parameters[index].id == 0 ? null : parameters[index].id,
              'name': parameters[index].name.trim(),
              'unit': parameters[index].unit?.trim().isEmpty ?? true
                  ? null
                  : parameters[index].unit!.trim(),
              'sortOrder': index,
              'status': parameters[index].status,
            },
        ],
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Measurement parameters response is empty.');
    }

    return data
        .map((item) {
          final json = item as Map<String, dynamic>;
          return MeasurementParameter(
            id: (json['id'] as num).toInt(),
            code: json['code'] as String,
            name: json['name'] as String,
            unit: json['unit'] as String?,
            sortOrder: (json['sortOrder'] as num).toInt(),
            status: json['status'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<void> createMeasurement(
    int memberId,
    NewMeasurement measurement,
  ) async {
    await _apiClient.post<void>(
      '/api/members/$memberId/measurements',
      data: {
        'measuredAt': measurement.measuredAt.toUtc().toIso8601String(),
        'note': measurement.note,
        'values': measurement.values
            .map(
              (value) => {
                'parameterId': value.parameterId,
                'value': value.value,
              },
            )
            .toList(growable: false),
      },
    );
  }
}
