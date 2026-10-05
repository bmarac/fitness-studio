import '../../domain/entities/member_progress.dart';

class MemberProgressModel extends MemberProgress {
  const MemberProgressModel({
    required super.latestValues,
    required super.history,
  });

  factory MemberProgressModel.fromJson({
    required Map<String, dynamic> latestJson,
    required List<dynamic> historyJson,
  }) {
    return MemberProgressModel(
      latestValues: (latestJson['values'] as List<dynamic>)
          .map(
            (value) =>
                _value(value as Map<String, dynamic>, includeMeasuredAt: true),
          )
          .toList(growable: false),
      history: historyJson
          .map((item) => _measurement(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static ProgressMeasurement _measurement(Map<String, dynamic> json) {
    return ProgressMeasurement(
      id: json['id'] as int,
      measuredAt: DateTime.parse(json['measuredAt'] as String).toLocal(),
      note: json['note'] as String?,
      values: (json['values'] as List<dynamic>)
          .map((value) => _value(value as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  static ProgressValue _value(
    Map<String, dynamic> json, {
    bool includeMeasuredAt = false,
  }) {
    return ProgressValue(
      parameterId: json['parameterId'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String?,
      value: (json['value'] as num).toDouble(),
      decimalPlaces: json['decimalPlaces'] as int,
      sortOrder: json['sortOrder'] as int,
      source: json['source'] as String,
      measuredAt: includeMeasuredAt
          ? DateTime.parse(json['measuredAt'] as String).toLocal()
          : null,
    );
  }
}
