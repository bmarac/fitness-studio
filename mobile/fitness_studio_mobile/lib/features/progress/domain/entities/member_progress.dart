class MemberProgress {
  const MemberProgress({required this.latestValues, required this.history});

  final List<ProgressValue> latestValues;
  final List<ProgressMeasurement> history;

  ProgressValue? latestByCode(String code) {
    for (final value in latestValues) {
      if (value.code == code) return value;
    }
    return null;
  }

  List<ProgressPoint> pointsFor(String code) {
    final points = <ProgressPoint>[];
    for (final measurement in history.reversed) {
      for (final value in measurement.values) {
        if (value.code == code) {
          points.add(
            ProgressPoint(
              measuredAt: measurement.measuredAt,
              value: value.value,
              note: measurement.note,
            ),
          );
          break;
        }
      }
    }
    return points;
  }

  double? changeFor(String code) {
    final points = pointsFor(code);
    if (points.length < 2) return null;
    return points.last.value - points[points.length - 2].value;
  }
}

class ProgressMeasurement {
  const ProgressMeasurement({
    required this.id,
    required this.measuredAt,
    required this.note,
    required this.values,
  });

  final int id;
  final DateTime measuredAt;
  final String? note;
  final List<ProgressValue> values;
}

class ProgressValue {
  const ProgressValue({
    required this.parameterId,
    required this.code,
    required this.name,
    required this.unit,
    required this.value,
    required this.decimalPlaces,
    required this.sortOrder,
    required this.source,
    this.measuredAt,
  });

  final int parameterId;
  final String code;
  final String name;
  final String? unit;
  final double value;
  final int decimalPlaces;
  final int sortOrder;
  final String source;
  final DateTime? measuredAt;

  String get formattedValue {
    final number = value.toStringAsFixed(decimalPlaces);
    return unit == null || unit!.isEmpty ? number : '$number $unit';
  }
}

class ProgressPoint {
  const ProgressPoint({
    required this.measuredAt,
    required this.value,
    required this.note,
  });

  final DateTime measuredAt;
  final double value;
  final String? note;
}
