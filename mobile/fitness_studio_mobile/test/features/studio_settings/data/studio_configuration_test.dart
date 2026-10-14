import 'package:fitness_studio_mobile/features/studio_settings/data/studio_settings_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and serializes the unified studio configuration', () {
    final configuration = StudioConfiguration.fromJson({
      'joinByCodeEnabled': true,
      'joinCode': 'STAYFIT',
      'recipientName': 'Stay Fit',
      'iban': 'HR1210010051863000160',
      'paymentModel': 'HR00',
      'paymentReference': '123',
      'paymentDescription': 'Članarina',
      'memberReminderDays': [1, 3],
      'adminReminderDays': [5],
      'notificationTime': '09:00:00',
      'cancellationCutoffHours': 12,
      'isPaymentComplete': true,
    });

    expect(configuration.joinCode, 'STAYFIT');
    expect(configuration.memberReminderDays, [1, 3]);
    expect(configuration.cancellationCutoffHours, 12);
    expect(configuration.toJson(), {
      'joinByCodeEnabled': true,
      'joinCode': 'STAYFIT',
      'recipientName': 'Stay Fit',
      'iban': 'HR1210010051863000160',
      'paymentModel': 'HR00',
      'paymentReference': '123',
      'paymentDescription': 'Članarina',
      'memberReminderDays': [1, 3],
      'adminReminderDays': [5],
      'notificationTime': '09:00:00',
      'cancellationCutoffHours': 12,
    });
  });
}
