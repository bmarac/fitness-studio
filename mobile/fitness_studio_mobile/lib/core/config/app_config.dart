class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.currentStudioId});

  final String apiBaseUrl;
  final int currentStudioId;

  static const local = AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5146',
    ),
    currentStudioId: int.fromEnvironment('CURRENT_STUDIO_ID', defaultValue: 1),
  );
}
