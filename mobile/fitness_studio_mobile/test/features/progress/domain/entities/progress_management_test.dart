import 'package:fitness_studio_mobile/features/progress/domain/entities/progress_management.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeasurementParameter.canEnter', () {
    MeasurementParameter parameter({String status = 'active'}) {
      return MeasurementParameter(
        id: 1,
        code: 'weight_kg',
        name: 'Težina',
        unit: 'kg',
        sortOrder: 1,
        status: status,
      );
    }

    test('allows active parameters', () {
      expect(parameter().canEnter, isTrue);
    });

    test('rejects inactive parameters', () {
      expect(parameter(status: 'inactive').canEnter, isFalse);
    });
  });
}
