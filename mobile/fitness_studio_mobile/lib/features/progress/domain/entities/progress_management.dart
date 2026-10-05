class ProgressMember {
  const ProgressMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.status,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String status;

  String get fullName => '$firstName $lastName';
}

class MeasurementParameter {
  const MeasurementParameter({
    required this.id,
    required this.code,
    required this.name,
    required this.unit,
    required this.source,
    required this.minValue,
    required this.maxValue,
    required this.decimalPlaces,
    required this.sortOrder,
    required this.status,
  });

  final int id;
  final String code;
  final String name;
  final String? unit;
  final String source;
  final double? minValue;
  final double? maxValue;
  final int decimalPlaces;
  final int sortOrder;
  final String status;

  bool get canEnter => source == 'manual' && status == 'active';
}

class NewMeasurementValue {
  const NewMeasurementValue({required this.parameterId, required this.value});

  final int parameterId;
  final double value;
}

class NewMeasurement {
  const NewMeasurement({
    required this.measuredAt,
    required this.values,
    this.note,
  });

  final DateTime measuredAt;
  final String? note;
  final List<NewMeasurementValue> values;
}
