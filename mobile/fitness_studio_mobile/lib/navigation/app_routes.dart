class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';

  static const login = '/login';
  static const register = '/registracija';
  static const registerPath = register;
  static const studioSelection = '/odabir-studija';
  static const studioSelectionPath = studioSelection;

  static const classSessions = '/termini';

  static const classSessionDetails = 'termin/:id';

  static const myWorkouts = '/moji-treninzi';

  static const profile = '/profil';

  static const progress = 'napredak';

  static const progressPath = '$profile/napredak';

  static const membersProgress = 'clanovi';

  static const memberProgress = 'clanovi/:memberId/napredak';

  static const createMeasurement = 'clanovi/:memberId/novo-mjerenje';

  static const payments = 'clanarine';
  static const membershipPlans = 'paketi';
  static const notifications = 'obavijesti';
  static const trainers = 'treneri';
  static const legacyOnboarding = 'onboarding';
  static const studioSettings = 'postavke-studija';
  static const createTrainer = 'novi-trener';
  static const legacyCreateMemberOnboarding = 'onboarding/novi-clan';
  static const legacyCreateTrainerOnboarding = 'onboarding/novi-trener';
  static const paymentsPath = '$profile/clanarine';
  static const membershipPlansPath = '$profile/paketi';
  static const notificationsPath = '$profile/obavijesti';
  static const trainersPath = '$profile/treneri';
  static const studioSettingsPath = '$profile/postavke-studija';
  static const createTrainerPath = '$profile/treneri/novi-trener';

  static const membersProgressPath = '$profile/clanovi';

  static String memberProgressPath(int memberId) {
    return '$profile/clanovi/$memberId/napredak';
  }

  static String createMeasurementPath(int memberId) {
    return '$profile/clanovi/$memberId/novo-mjerenje';
  }

  static String classSessionDetailsPath(int id) {
    return '$classSessions/termin/$id';
  }
}
