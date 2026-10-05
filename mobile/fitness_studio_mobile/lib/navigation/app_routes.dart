class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';

  static const login = '/login';

  static const classSessions = '/termini';

  static const classSessionDetails = 'termin/:id';

  static const createSchedule = 'novi-termin';

  static const myWorkouts = '/moji-treninzi';

  static const profile = '/profil';

  static const progress = 'napredak';

  static const progressPath = '$profile/napredak';

  static const membersProgress = 'clanovi';

  static const memberProgress = 'clanovi/:memberId/napredak';

  static const createMeasurement = 'clanovi/:memberId/novo-mjerenje';

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

  static const createSchedulePath = '$classSessions/novi-termin';
}
