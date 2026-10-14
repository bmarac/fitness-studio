// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get appTitle => 'Fitness Studio';

  @override
  String get navClassSessions => 'Termini';

  @override
  String get navRecurringSchedules => 'Rasporedi';

  @override
  String get navMyWorkouts => 'Moji treninzi';

  @override
  String get navProfile => 'Profil';

  @override
  String get actionCancel => 'Odustani';

  @override
  String get actionClose => 'Zatvori';

  @override
  String get actionConfirm => 'Potvrdi';

  @override
  String get actionContinue => 'Nastavi';

  @override
  String get actionRetry => 'Pokušaj ponovno';

  @override
  String get actionSave => 'Spremi';

  @override
  String get actionSaving => 'Spremam...';

  @override
  String get actionEdit => 'Uredi';

  @override
  String get actionDelete => 'Obriši';

  @override
  String get actionRemove => 'Ukloni';

  @override
  String get labelEmail => 'E-mail';

  @override
  String get labelPassword => 'Lozinka';

  @override
  String get labelTrainer => 'Trener';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelDate => 'Datum';

  @override
  String get labelTime => 'Vrijeme';

  @override
  String get labelDuration => 'Trajanje';

  @override
  String get labelCapacity => 'Kapacitet';

  @override
  String get labelMember => 'Član';

  @override
  String get labelNotes => 'Napomena';

  @override
  String get notificationsTitle => 'Obavijesti';

  @override
  String get logoutTitle => 'Odjava';

  @override
  String get logoutTooltip => 'Odjavi se';

  @override
  String get logoutQuestion => 'Želiš li se odjaviti iz aplikacije?';

  @override
  String get logoutAction => 'Odjavi se';

  @override
  String get logoutInProgress => 'Odjavljujem...';

  @override
  String get loginSubtitle => 'Prijavi se u svoj studio';

  @override
  String get loginAction => 'Prijavi se';

  @override
  String get loginInProgress => 'Prijava...';

  @override
  String get loginSuccess => 'Prijava je uspješna.';

  @override
  String get showPassword => 'Prikaži lozinku';

  @override
  String get hidePassword => 'Sakrij lozinku';

  @override
  String get invalidEmail => 'Unesi ispravnu e-mail adresu.';

  @override
  String get passwordRequired => 'Unesi lozinku.';

  @override
  String get profileMyPlan => 'Moj paket';

  @override
  String get profileValid => 'Vrijedi';

  @override
  String profileValidFrom(String date) {
    return 'Od $date';
  }

  @override
  String profileValidRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get profileUsedThisWeek => 'Iskorišteno ovaj tjedan';

  @override
  String get profileUsedThisMonth => 'Iskorišteno ovaj mjesec';

  @override
  String get profileUsedInMembership => 'Iskorišteno u članarini';

  @override
  String get profileUsedInBillingCycle => 'Iskorišteno u obračunskom periodu';

  @override
  String get profileMembersProgress => 'Antropometrija članova';

  @override
  String get profileMembersProgressSubtitle => 'Pregled i unos mjerenja';

  @override
  String get profileMyPayments => 'Moja članarina';

  @override
  String get profileAdminPayments => 'Naplata članarina';

  @override
  String get profileMyPaymentsSubtitle => 'Podaci za uplatu i povijest';

  @override
  String get profileAdminPaymentsSubtitle => 'Pregled i potvrda uplata';

  @override
  String get profilePaymentSettings => 'Postavke plaćanja';

  @override
  String get profilePaymentSettingsSubtitle =>
      'Primatelj, IBAN i podaci za uplatu';

  @override
  String get profileAnthropometry => 'Antropometrija';

  @override
  String get profileAnthropometrySubtitle => 'Tjelesna mjerenja';

  @override
  String get profileFixedSchedules => 'Fiksni termini';

  @override
  String get profileAboutMe => 'O meni';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleTrainer => 'Trener';

  @override
  String get roleMember => 'Član';

  @override
  String get statusActive => 'Aktivan';

  @override
  String get statusPaused => 'Pauziran';

  @override
  String get statusInactive => 'Neaktivan';

  @override
  String get statusCompleted => 'Završeno';

  @override
  String unknownDay(int day) {
    return 'Dan $day';
  }

  @override
  String get classSessionsTitle => 'Termini';

  @override
  String get schedulesTooltip => 'Upravljaj rasporedima';

  @override
  String get noClassSessionsTitle => 'Nema termina';

  @override
  String get noClassSessionsMessage =>
      'Trenutno nema raspisanih grupnih treninga.';

  @override
  String spotsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mjesta',
      few: '$count mjesta',
      one: '1 mjesto',
    );
    return '$_temp0';
  }

  @override
  String get classFull => 'Popunjeno';

  @override
  String get previousWeek => 'Prethodni tjedan';

  @override
  String get nextWeek => 'Sljedeći tjedan';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count termina',
      few: '$count termina',
      one: '1 termin',
      zero: 'nema termina',
    );
    return '$_temp0';
  }

  @override
  String daySessionsSemantics(String day, String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count termina',
      few: '$count termina',
      one: '1 termin',
      zero: 'nema termina',
    );
    return '$day, $date, $_temp0';
  }

  @override
  String get classSessionDetailsTitle => 'Detalji termina';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get labelBookingAvailability => 'Rezervacija';

  @override
  String get bookingAvailable => 'Dostupna';

  @override
  String get bookingUnavailable => 'Nije dostupna';

  @override
  String get occupancyTitle => 'Popunjenost';

  @override
  String reservedCapacity(int booked, int capacity) {
    return '$booked/$capacity rezervirano';
  }

  @override
  String freeSpots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mjesta slobodno',
      few: '$count mjesta slobodno',
      one: '1 mjesto slobodno',
    );
    return '$_temp0';
  }

  @override
  String get classIsFull => 'Termin je pun';

  @override
  String get bookAction => 'Rezerviraj';

  @override
  String get bookingInProgress => 'Rezerviram...';

  @override
  String get bookingSaved => 'Rezervacija je spremljena.';

  @override
  String get cancelSessionTitle => 'Otkaži termin';

  @override
  String get cancelSessionAction => 'Otkaži termin';

  @override
  String get cancelOnlyThisSession => 'Otkaži ovaj termin';

  @override
  String get cancelOnlyThisSessionQuestion =>
      'Želiš li otkazati samo ovaj termin? Budući termini iz rasporeda ostat će aktivni.';

  @override
  String get cancellingSession => 'Otkazujem...';

  @override
  String get sessionCancelled => 'Termin je otkazan.';

  @override
  String get loggedUserNotMember =>
      'Prijavljeni korisnik nije povezan s članom.';

  @override
  String get pauseSchedule => 'Pauziraj raspored';

  @override
  String get resumeSchedule => 'Nastavi raspored';

  @override
  String get finishSchedule => 'Završi raspored';

  @override
  String get pauseAction => 'Pauziraj';

  @override
  String get resumeAction => 'Nastavi';

  @override
  String get finishAction => 'Završi';

  @override
  String get pauseScheduleMessage =>
      'Od odabranog datuma otkazat će se ovaj i svi budući termini rasporeda. Raspored se kasnije može nastaviti.';

  @override
  String get resumeScheduleMessage =>
      'Od odabranog datuma ponovno će se kreirati termini i rezervacije aktivnih fiksnih članova.';

  @override
  String get finishScheduleMessage =>
      'Od odabranog datuma raspored i povezane fiksne dodjele trajno završavaju. Ovu radnju nije moguće poništiti.';

  @override
  String get schedulePaused => 'Raspored je pauziran.';

  @override
  String get scheduleResumed => 'Raspored je nastavljen.';

  @override
  String get scheduleEnded => 'Raspored je završen.';

  @override
  String get attendeesTitle => 'Polaznici';

  @override
  String attendeesCapacity(int count, int capacity) {
    return 'Polaznici ($count/$capacity)';
  }

  @override
  String get loadingAttendees => 'Učitavam polaznike...';

  @override
  String get attendeesLoadError => 'Polaznike trenutno nije moguće učitati.';

  @override
  String get noAttendees => 'Nema prijavljenih polaznika.';

  @override
  String get attendedTooltip => 'Prisutan';

  @override
  String get noShowTooltip => 'Nije došao';

  @override
  String get memberActionsTooltip => 'Akcije za člana';

  @override
  String get removeFromSession => 'Ukloni s ovog termina';

  @override
  String get removeFromFixedGroup => 'Ukloni iz fiksne grupe';

  @override
  String get removeFromSessionShort => 'Ukloni s termina';

  @override
  String get removeFixedGroupWarning =>
      'Član će biti uklonjen s ovog i svih budućih termina iz ove fiksne grupe.';

  @override
  String get removeSessionWarning =>
      'Član će biti uklonjen samo s ovog termina.';

  @override
  String get removedFromFixedGroup => 'Član je uklonjen iz fiksne grupe.';

  @override
  String get removedFromSession => 'Član je uklonjen s termina.';

  @override
  String get myWorkoutsTitle => 'Moji treninzi';

  @override
  String get filterWorkouts => 'Filtriraj treninge';

  @override
  String get filterActive => 'Aktivni';

  @override
  String get filterCompleted => 'Završeni';

  @override
  String get filterCancelled => 'Otkazani';

  @override
  String get filterAll => 'Svi';

  @override
  String get allTrainers => 'Svi treneri';

  @override
  String get noReservedWorkouts => 'Nema rezerviranih treninga.';

  @override
  String get noSessions => 'Nema termina.';

  @override
  String cancelBookingDetails(String className, String date, String time) {
    return '$className\n$date u $time';
  }

  @override
  String get bookingStatusAttended => 'Odrađeno';

  @override
  String get bookingStatusNoShow => 'Nije došao';

  @override
  String get bookingStatusCancelled => 'Otkazano';

  @override
  String get bookingStatusWaitlisted => 'Lista čekanja';

  @override
  String get bookingStatusBooked => 'Rezervirano';

  @override
  String get activeWorkouts => 'Aktivni treninzi';

  @override
  String get completedWorkouts => 'Završeni treninzi';

  @override
  String get cancelledWorkouts => 'Otkazani treninzi';

  @override
  String get allWorkouts => 'Svi treninzi';

  @override
  String attendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count polaznika',
      few: '$count polaznika',
      one: '1 polaznik',
    );
    return '$_temp0';
  }

  @override
  String get sessionStatusCancelled => 'Otkazan';

  @override
  String get sessionStatusCompleted => 'Završen';

  @override
  String get sessionStatusScheduled => 'Zakazan';

  @override
  String get progressTitle => 'Antropometrija';

  @override
  String get measurementAction => 'Mjerenje';

  @override
  String get noMemberProfileTitle => 'Nema članskog profila';

  @override
  String get noMemberProfileMessage =>
      'Antropometrijska mjerenja dostupna su članovima.';

  @override
  String get noMeasurementsTitle => 'Nema mjerenja';

  @override
  String get noMeasurementsMessage =>
      'Još nema zabilježenih antropometrijskih mjerenja.';

  @override
  String get parameterLabel => 'Parametar';

  @override
  String get currentValue => 'Trenutno';

  @override
  String get chartNeedsTwoMeasurements =>
      'Za graf su potrebna barem dva mjerenja.';

  @override
  String get progressTrend => 'Kretanje';

  @override
  String get progressHistory => 'Povijest';

  @override
  String get membersProgressTitle => 'Antropometrija članova';

  @override
  String get searchMembers => 'Pretraži članove';

  @override
  String get noMembersFound => 'Nema pronađenih članova.';

  @override
  String get newMeasurementTitle => 'Novo mjerenje';

  @override
  String get enterOneMeasuredParameter =>
      'Unesi barem jedan izmjereni parametar.';

  @override
  String get saveMeasurement => 'Spremi mjerenje';

  @override
  String get invalidNumber => 'Unesi ispravan broj.';

  @override
  String minimumValue(String value) {
    return 'Najmanja vrijednost je $value.';
  }

  @override
  String maximumValue(String value) {
    return 'Najveća vrijednost je $value.';
  }

  @override
  String get enterOneValue => 'Unesi barem jednu vrijednost.';

  @override
  String get newScheduleTitle => 'Novi raspored';

  @override
  String get recurringScheduleDescription =>
      'Termin će se ponavljati svaki tjedan od odabranog datuma.';

  @override
  String get missingClassTypesOrTrainers =>
      'Nedostaju vrste treninga ili treneri.';

  @override
  String get classTypeLabel => 'Vrsta treninga';

  @override
  String get dayLabel => 'Dan';

  @override
  String get startTimeLabel => 'Vrijeme početka';

  @override
  String get durationMinutesLabel => 'Trajanje (min)';

  @override
  String get positiveNumberRequired => 'Unesi broj veći od 0.';

  @override
  String get validFromLabel => 'Vrijedi od';

  @override
  String get saveSchedule => 'Spremi raspored';

  @override
  String get scheduleCreated => 'Raspored je spremljen.';

  @override
  String get schedulesTitle => 'Rasporedi';

  @override
  String get filterSchedules => 'Filtriraj rasporede';

  @override
  String scheduleFixedOccupancy(int active, int capacity) {
    return '$active/$capacity članova';
  }

  @override
  String get noSchedules => 'Nema kreiranih rasporeda.';

  @override
  String get activeSchedules => 'Aktivni';

  @override
  String get pausedSchedules => 'Pauzirani';

  @override
  String get completedSchedules => 'Završeni';

  @override
  String get manageSchedule => 'Upravljaj rasporedom';

  @override
  String effectiveFromDate(String date) {
    return 'od $date';
  }

  @override
  String get paymentSettingsTitle => 'Postavke plaćanja';

  @override
  String get recipientLabel => 'Primatelj';

  @override
  String get paymentModelLabel => 'Model';

  @override
  String get paymentReferenceLabel => 'Poziv na broj';

  @override
  String get paymentDescriptionLabel => 'Opis plaćanja';

  @override
  String get memberReminderDaysLabel =>
      'Podsjetnici članu (dani nakon dospijeća)';

  @override
  String get adminReminderDaysLabel => 'Podsjetnici adminu';

  @override
  String get sendTimeLabel => 'Vrijeme slanja (HH:mm)';

  @override
  String get requiredField => 'Ovo polje je obvezno.';

  @override
  String get settingsSaved => 'Postavke su spremljene.';

  @override
  String get noPaymentsInCategory => 'Nema obračuna u ovoj kategoriji.';

  @override
  String get paymentFilterPending => 'Za naplatu';

  @override
  String get paymentFilterReported => 'Čeka potvrdu';

  @override
  String get paymentFilterOverdue => 'Kasni';

  @override
  String get paymentFilterPaid => 'Plaćeno';

  @override
  String get paymentFilterAll => 'Sve';

  @override
  String get paymentRecipient => 'Primatelj';

  @override
  String get paymentModelAndReference => 'Model i poziv';

  @override
  String get paymentDescription => 'Opis';

  @override
  String paymentDueSummary(
    String plan,
    String period,
    String amount,
    String status,
    String dueDate,
  ) {
    return '$plan · $period\n$amount · $status · dospijeće $dueDate';
  }

  @override
  String get paymentStatusUnpaid => 'Neplaćeno';

  @override
  String get paymentCode => 'Kod za plaćanje';

  @override
  String get paymentReported => 'Uplatio sam';

  @override
  String get rejectPaymentReport => 'Odbij prijavu';

  @override
  String get reopenPayment => 'Ponovno otvori';

  @override
  String get endMembership => 'Završi članstvo';

  @override
  String endMembershipSummary(String date, String amount) {
    return 'Prvi dan kada više ne treniram: $date\nProcijenjeni zadnji iznos: $amount';
  }

  @override
  String get markPaid => 'Označi plaćeno';

  @override
  String get changeSaved => 'Promjena je spremljena.';

  @override
  String get hub3PaymentCode => 'HUB3 kod za plaćanje';

  @override
  String get billingNotEnabled => 'Naplata nije uključena';

  @override
  String get allMembershipsBillingEnabled =>
      'Sva aktivna članstva imaju uključenu naplatu.';

  @override
  String get enableBilling => 'Uključi naplatu';

  @override
  String get activeBilling => 'Aktivna naplata';

  @override
  String get noActiveBilling => 'Nema članstava s aktivnom naplatom.';

  @override
  String membershipStarted(String date) {
    return 'Početak članstva: $date';
  }

  @override
  String get billingValidFrom => 'Naplata vrijedi od';

  @override
  String get retroactiveBilling => 'Retroaktivna naplata';

  @override
  String billingStartsSummary(String plan, String start, String next) {
    return '$plan\nNaplata vrijedi od: $start\nSljedeći obračun: $next';
  }

  @override
  String retroactiveBillingWarning(String date) {
    return 'Odabrali ste $date. Odmah će nastati sve mjesečne obveze od tog datuma do aktualnog ciklusa.';
  }

  @override
  String get billingEnabled => 'Naplata je uključena.';

  @override
  String billingEnabledWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kreirano je $count obračuna.',
      few: 'Kreirana su $count obračuna.',
      one: 'Kreiran je 1 obračun.',
    );
    return 'Naplata je uključena. $_temp0';
  }

  @override
  String get noNextBilling => 'nema';

  @override
  String get failureRestoreSession => 'Nije moguće učitati spremljenu prijavu.';

  @override
  String get failureLogout => 'Odjava trenutno nije moguća. Pokušaj ponovno.';

  @override
  String get failureLoginResponse =>
      'Nije moguće pročitati odgovor za prijavu.';

  @override
  String get failureSaveSession => 'Nije moguće sigurno spremiti prijavu.';

  @override
  String get failureReadApi => 'Nije moguće pročitati podatke s API-ja.';

  @override
  String get failureReadBookings => 'Nije moguće pročitati rezervacije.';

  @override
  String get failureReadTrainers => 'Nije moguće pročitati trenere.';

  @override
  String get failureReadSchedules => 'Nije moguće pročitati rasporede.';

  @override
  String get failureReadScheduleForm =>
      'Nije moguće pročitati podatke za novi termin.';

  @override
  String get failureReadScheduleResponse =>
      'Nije moguće pročitati odgovor za novi termin.';

  @override
  String get failureReadProgress =>
      'Nije moguće pročitati antropometrijska mjerenja.';

  @override
  String get failureReadMembers => 'Nije moguće učitati članove.';

  @override
  String get failureReadMeasurementParameters =>
      'Nije moguće učitati parametre mjerenja.';

  @override
  String get failureSaveMeasurement => 'Mjerenje nije moguće spremiti.';

  @override
  String get failureBookingAlreadyExists =>
      'Već ste prijavljeni na ovaj termin.';

  @override
  String get failureMembershipRequired =>
      'Nemate paket koji vrijedi na datum ovog termina.';

  @override
  String get failureMembershipLimitReached =>
      'Iskoristili ste sve termine dostupne u paketu za ovo razdoblje.';

  @override
  String get failureNotFound => 'Traženi podatak nije pronađen.';

  @override
  String get failureNetwork => 'Mrežni zahtjev nije uspio.';

  @override
  String get labelStudioCode => 'Kod studija';

  @override
  String get studioCodeRequired => 'Unesi kod studija.';

  @override
  String get trainersTitle => 'Treneri';

  @override
  String get trainerManagementSubtitle => 'Pregledaj i unaprijed dodaj trenere';

  @override
  String get membershipPlansTitle => 'Cjenik';

  @override
  String get membershipPlansSubtitle => 'Upravljaj cjenikom';

  @override
  String get memberPackagesTitle => 'Članovi i paketi';

  @override
  String get memberPackagesSubtitle => 'Dodijeli ili promijeni paket članu';

  @override
  String get memberPackagesFilterAll => 'Svi članovi';

  @override
  String memberPackagesFilterMissing(int count) {
    return 'Bez paketa ($count)';
  }

  @override
  String get memberPackageMissing => 'Nema aktivnog paketa';

  @override
  String memberPackageFrom(String start) {
    return 'Vrijedi od $start';
  }

  @override
  String memberPackagePeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get memberPackageInactiveMemberHint =>
      'Pakete nije moguće mijenjati neaktivnom članu.';

  @override
  String get assignMemberPackage => 'Dodijeli paket';

  @override
  String get changeMemberPackage => 'Promijeni paket';

  @override
  String assignPackageTo(String memberName) {
    return 'Dodijeli paket: $memberName';
  }

  @override
  String changePackageFor(String memberName) {
    return 'Promijeni paket: $memberName';
  }

  @override
  String get memberPackageStartsOn => 'Početak članstva';

  @override
  String get memberPackageEndsOn => 'Kraj članstva';

  @override
  String get memberPackageNoEndDate => 'Bez datuma završetka';

  @override
  String get memberPackageClearEnd => 'Ukloni datum završetka';

  @override
  String get memberPackagePlanRequired => 'Odaberi paket.';

  @override
  String get memberPackageEndAfterStart =>
      'Datum završetka mora biti nakon datuma početka.';

  @override
  String get memberPackageOverlap =>
      'Član već ima paket koji se preklapa s odabranim razdobljem.';

  @override
  String get noActiveMembershipPlans =>
      'Nema aktivnih paketa koje je moguće dodijeliti.';

  @override
  String memberPackageSaved(String memberName) {
    return 'Paket za člana $memberName je spremljen.';
  }

  @override
  String get addMembershipPlan => 'Dodaj paket';

  @override
  String get editMembershipPlan => 'Uredi paket';

  @override
  String get noMembershipPlans => 'Još nema paketa.';

  @override
  String get membershipPlanName => 'Naziv paketa';

  @override
  String get membershipPlanDescription => 'Opis';

  @override
  String get membershipPlanPrice => 'Mjesečna cijena';

  @override
  String get membershipPlanLimitEnabled => 'Ograniči broj termina';

  @override
  String get membershipPlanSessionLimit => 'Broj termina';

  @override
  String get membershipPlanLimitPeriod => 'Razdoblje ograničenja';

  @override
  String get membershipPlanPeriodWeek => 'Tjedan';

  @override
  String get membershipPlanPeriodMonth => 'Mjesec';

  @override
  String get membershipPlanPeriodMembership => 'Članstvo';

  @override
  String get membershipPlanUnlimited => 'Neograničen broj termina';

  @override
  String membershipPlanMonthlyPrice(String price) {
    return '$price mjesečno';
  }

  @override
  String membershipPlanLimitSummary(int count, String period) {
    return '$count termina / $period';
  }

  @override
  String get membershipPlanActive => 'Aktivan paket';

  @override
  String get deleteMembershipPlanTitle => 'Obriši paket?';

  @override
  String deleteMembershipPlanQuestion(String name) {
    return 'Paket $name bit će trajno obrisan.';
  }

  @override
  String get membershipPlanCreated => 'Paket je dodan.';

  @override
  String get membershipPlanUpdated => 'Paket je spremljen.';

  @override
  String get membershipPlanDeleted => 'Paket je obrisan.';

  @override
  String get membershipPlanCannotDeleteTitle => 'Paket se ne može obrisati';

  @override
  String get membershipPlanCannotDeleteMessage =>
      'Paket je povezan s postojećim članstvima. Možeš ga označiti neaktivnim.';

  @override
  String get deactivateMembershipPlan => 'Označi neaktivnim';

  @override
  String get membershipPlanDeactivated => 'Paket je označen neaktivnim.';

  @override
  String get membershipPlanDuplicate => 'Paket s tim nazivom već postoji.';

  @override
  String get invalidMembershipPlanPrice => 'Unesi ispravnu nenegativnu cijenu.';

  @override
  String get invalidMembershipPlanLimit =>
      'Broj termina mora biti pozitivan cijeli broj.';

  @override
  String get addTrainer => 'Novi trener';

  @override
  String get noTrainersYet => 'Još nema trenera.';

  @override
  String get firstName => 'Ime';

  @override
  String get lastName => 'Prezime';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get bioLabel => 'Biografija';

  @override
  String get saveAction => 'Spremi';

  @override
  String get registerTitle => 'Registracija';

  @override
  String get registerAction => 'Kreiraj račun';

  @override
  String get passwordMinimumLength => 'Lozinka mora imati najmanje 10 znakova.';

  @override
  String get chooseStudioTitle => 'Odaberi studio';

  @override
  String get yourStudios => 'Tvoji studiji';

  @override
  String get joinStudioTitle => 'Pridruži se studiju';

  @override
  String joinStudioConfirmation(String studioName) {
    return 'Pridruživanje studiju $studioName';
  }

  @override
  String get checkStudioCode => 'Provjeri kod';

  @override
  String get joinStudioAction => 'Pridruži se';

  @override
  String get firstAndLastNameRequired => 'Unesi ime i prezime.';

  @override
  String profileCreated(String displayName) {
    return 'Profil $displayName je kreiran.';
  }

  @override
  String get changeOrAddStudio => 'Promijeni ili dodaj studio';

  @override
  String get studioSettingsTitle => 'Postavke studija';

  @override
  String get studioSettingsSubtitle => 'Pristup, naplata i podsjetnici';

  @override
  String get studioAccessSettingsTitle => 'Pristup studiju';

  @override
  String get reminderSettingsTitle => 'Podsjetnici';

  @override
  String get allowJoinByCode => 'Dopusti povezivanje kodom';

  @override
  String get allowJoinByCodeDescription =>
      'Korisnici se mogu pridružiti unosom koda studija.';

  @override
  String get fixedScheduleMembers => 'Članovi';

  @override
  String get noFixedScheduleMembers =>
      'Ovaj raspored trenutačno nema članova u fiksnoj grupi.';

  @override
  String get addFixedScheduleMember => 'Dodaj člana';

  @override
  String get addFixedScheduleMemberAction => 'Dodaj u fiksnu grupu';

  @override
  String get fixedScheduleStartsOn => 'Početak fiksnog rasporeda';

  @override
  String get noMembersForFixedSchedule => 'Nema dostupnih aktivnih članova.';

  @override
  String fixedScheduleMemberAdded(String memberName) {
    return '$memberName je dodan/a u fiksnu grupu.';
  }

  @override
  String get fixedScheduleInactiveMember =>
      'Samo aktivan član može biti dodan u fiksnu grupu.';

  @override
  String get fixedScheduleInactiveSchedule =>
      'Člana je moguće dodati samo u aktivan raspored.';

  @override
  String get fixedScheduleAlreadyAssigned =>
      'Član je već dodan u ovaj fiksni raspored.';

  @override
  String get fixedScheduleFull => 'Fiksna grupa nema slobodnih mjesta.';

  @override
  String get fixedScheduleChanged =>
      'Raspored je u međuvremenu promijenjen. Pokušaj ponovno.';

  @override
  String get fixedSchedulePackageLimit =>
      'Paket člana ne dopušta dodatni fiksni termin.';

  @override
  String get moveFixedScheduleMember => 'Premjesti';

  @override
  String selectMoveDestination(String memberName) {
    return 'Odaberi novi raspored za $memberName';
  }

  @override
  String get cancelMove => 'Odustani od premještanja';

  @override
  String get moveDestinationFull => 'Raspored je popunjen';

  @override
  String get moveMemberTitle => 'Premjesti člana?';

  @override
  String moveMemberConfirmation(
    String memberName,
    String classType,
    String weekday,
    String time,
  ) {
    return 'Jeste li sigurni da želite premjestiti $memberName u $classType, $weekday u $time?';
  }

  @override
  String get confirmMove => 'Premjesti';

  @override
  String get fixedScheduleMemberMoved => 'Član je premješten u novi raspored.';

  @override
  String get scheduleMembersLoadError =>
      'Članove fiksne grupe nije moguće učitati.';
}
