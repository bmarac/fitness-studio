import '../../../core/network/api_client.dart';

class StudioConfiguration {
  const StudioConfiguration({
    required this.joinByCodeEnabled,
    required this.joinCode,
    required this.recipientName,
    required this.iban,
    required this.paymentModel,
    required this.paymentReference,
    required this.paymentDescription,
    required this.memberReminderDays,
    required this.adminReminderDays,
    required this.notificationTime,
    required this.cancellationCutoffHours,
    required this.isPaymentComplete,
  });

  final bool joinByCodeEnabled;
  final String? joinCode;
  final String recipientName;
  final String iban;
  final String paymentModel;
  final String paymentReference;
  final String paymentDescription;
  final List<int> memberReminderDays;
  final List<int> adminReminderDays;
  final String notificationTime;
  final int cancellationCutoffHours;
  final bool isPaymentComplete;

  StudioConfiguration copyWith({
    bool? joinByCodeEnabled,
    String? joinCode,
    String? recipientName,
    String? iban,
    String? paymentModel,
    String? paymentReference,
    String? paymentDescription,
    List<int>? memberReminderDays,
    List<int>? adminReminderDays,
    String? notificationTime,
    int? cancellationCutoffHours,
  }) => StudioConfiguration(
    joinByCodeEnabled: joinByCodeEnabled ?? this.joinByCodeEnabled,
    joinCode: joinCode ?? this.joinCode,
    recipientName: recipientName ?? this.recipientName,
    iban: iban ?? this.iban,
    paymentModel: paymentModel ?? this.paymentModel,
    paymentReference: paymentReference ?? this.paymentReference,
    paymentDescription: paymentDescription ?? this.paymentDescription,
    memberReminderDays: memberReminderDays ?? this.memberReminderDays,
    adminReminderDays: adminReminderDays ?? this.adminReminderDays,
    notificationTime: notificationTime ?? this.notificationTime,
    cancellationCutoffHours:
        cancellationCutoffHours ?? this.cancellationCutoffHours,
    isPaymentComplete: isPaymentComplete,
  );

  factory StudioConfiguration.fromJson(Map<String, dynamic> json) =>
      StudioConfiguration(
        joinByCodeEnabled: json['joinByCodeEnabled'] as bool,
        joinCode: json['joinCode'] as String?,
        recipientName: json['recipientName'] as String,
        iban: json['iban'] as String,
        paymentModel: json['paymentModel'] as String,
        paymentReference: json['paymentReference'] as String,
        paymentDescription: json['paymentDescription'] as String,
        memberReminderDays: (json['memberReminderDays'] as List<dynamic>)
            .cast<int>(),
        adminReminderDays: (json['adminReminderDays'] as List<dynamic>)
            .cast<int>(),
        notificationTime: json['notificationTime'] as String,
        cancellationCutoffHours: json['cancellationCutoffHours'] as int,
        isPaymentComplete: json['isPaymentComplete'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'joinByCodeEnabled': joinByCodeEnabled,
    'joinCode': joinCode,
    'recipientName': recipientName,
    'iban': iban,
    'paymentModel': paymentModel,
    'paymentReference': paymentReference,
    'paymentDescription': paymentDescription,
    'memberReminderDays': memberReminderDays,
    'adminReminderDays': adminReminderDays,
    'notificationTime': notificationTime,
    'cancellationCutoffHours': cancellationCutoffHours,
  };
}

class StudioSettingsRemoteDataSource {
  const StudioSettingsRemoteDataSource(this._api);

  final ApiClient _api;

  Future<StudioConfiguration> getConfiguration() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/studio-settings/configuration',
    );
    return StudioConfiguration.fromJson(response.data!);
  }

  Future<StudioConfiguration> updateConfiguration(
    StudioConfiguration configuration,
  ) async {
    final response = await _api.put<Map<String, dynamic>>(
      '/api/studio-settings/configuration',
      data: configuration.toJson(),
    );
    return StudioConfiguration.fromJson(response.data!);
  }
}
