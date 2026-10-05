import 'package:fitness_studio_mobile/features/progress/domain/entities/progress_management.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasurementParameter.canEnter', () {
    MeasurementParameter parameter({
      String source = 'manual',
      String status = 'active',
    }) {
      return MeasurementParameter(
        id: 1,
        code: 'weight_kg',
        name: 'Težina',
        unit: 'kg',
        source: source,
        minValue: 20,
        maxValue: 300,
        decimalPlaces: 1,
        sortOrder: 1,
        status: status,
      );
    }

    test('allows active manual parameters', () {
      expect(parameter().canEnter, isTrue);
    });

    test('rejects calculated and inactive parameters', () {
      expect(parameter(source: 'calculated').canEnter, isFalse);
      expect(parameter(status: 'inactive').canEnter, isFalse);
    });
  });
}
