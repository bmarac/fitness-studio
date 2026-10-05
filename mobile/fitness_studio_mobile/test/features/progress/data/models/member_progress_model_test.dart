import 'package:fitness_studio_mobile/features/progress/data/models/member_progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses progress and calculates chronological change', () {
    final model = MemberProgressModel.fromJson(
      latestJson: {
        'values': [
          {
            'parameterId': 2,
            'code': 'weight_kg',
            'name': 'Tezina',
            'unit': 'kg',
            'value': 68.4,
            'decimalPlaces': 1,
            'sortOrder': 20,
            'source': 'manual',
            'measuredAt': '2026-09-25T10:00:00Z',
          },
        ],
      },
      historyJson: [
        {
          'id': 2,
          'measuredAt': '2026-09-25T10:00:00Z',
          'note': 'Trenutno stanje',
          'values': [
            {
              'parameterId': 2,
              'code': 'weight_kg',
              'name': 'Tezina',
              'unit': 'kg',
              'value': 68.4,
              'decimalPlaces': 1,
              'sortOrder': 20,
              'source': 'manual',
            },
          ],
        },
        {
          'id': 1,
          'measuredAt': '2026-08-25T10:00:00Z',
          'note': 'Mjesecna kontrola',
          'values': [
            {
              'parameterId': 2,
              'code': 'weight_kg',
              'name': 'Tezina',
              'unit': 'kg',
              'value': 70.5,
              'decimalPlaces': 1,
              'sortOrder': 20,
              'source': 'manual',
            },
          ],
        },
      ],
    );

    expect(model.latestByCode('weight_kg')?.formattedValue, '68.4 kg');
    expect(model.pointsFor('weight_kg').map((point) => point.value), [
      70.5,
      68.4,
    ]);
    expect(model.changeFor('weight_kg'), closeTo(-2.1, 0.0001));
  });
}
