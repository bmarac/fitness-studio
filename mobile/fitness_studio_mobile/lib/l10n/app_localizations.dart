import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In hr, this message translates to:
  /// **'Fitness Studio'**
  String get appTitle;

  /// No description provided for @navClassSessions.
  ///
  /// In hr, this message translates to:
  /// **'Termini'**
  String get navClassSessions;

  /// No description provided for @navRecurringSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Rasporedi'**
  String get navRecurringSchedules;

  /// No description provided for @navMyWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Moji treninzi'**
  String get navMyWorkouts;

  /// No description provided for @navProfile.
  ///
  /// In hr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @actionCancel.
  ///
  /// In hr, this message translates to:
  /// **'Odustani'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In hr, this message translates to:
  /// **'Zatvori'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In hr, this message translates to:
  /// **'Potvrdi'**
  String get actionConfirm;

  /// No description provided for @actionContinue.
  ///
  /// In hr, this message translates to:
  /// **'Nastavi'**
  String get actionContinue;

  /// No description provided for @actionRetry.
  ///
  /// In hr, this message translates to:
  /// **'Pokušaj ponovno'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In hr, this message translates to:
  /// **'Spremi'**
  String get actionSave;

  /// No description provided for @actionSaving.
  ///
  /// In hr, this message translates to:
  /// **'Spremam...'**
  String get actionSaving;

  /// No description provided for @actionEdit.
  ///
  /// In hr, this message translates to:
  /// **'Uredi'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In hr, this message translates to:
  /// **'Obriši'**
  String get actionDelete;

  /// No description provided for @actionRemove.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni'**
  String get actionRemove;

  /// No description provided for @labelEmail.
  ///
  /// In hr, this message translates to:
  /// **'E-mail'**
  String get labelEmail;

  /// No description provided for @labelPassword.
  ///
  /// In hr, this message translates to:
  /// **'Lozinka'**
  String get labelPassword;

  /// No description provided for @labelTrainer.
  ///
  /// In hr, this message translates to:
  /// **'Trener'**
  String get labelTrainer;

  /// No description provided for @labelStatus.
  ///
  /// In hr, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelDate.
  ///
  /// In hr, this message translates to:
  /// **'Datum'**
  String get labelDate;

  /// No description provided for @labelTime.
  ///
  /// In hr, this message translates to:
  /// **'Vrijeme'**
  String get labelTime;

  /// No description provided for @labelDuration.
  ///
  /// In hr, this message translates to:
  /// **'Trajanje'**
  String get labelDuration;

  /// No description provided for @labelCapacity.
  ///
  /// In hr, this message translates to:
  /// **'Kapacitet'**
  String get labelCapacity;

  /// No description provided for @labelMember.
  ///
  /// In hr, this message translates to:
  /// **'Član'**
  String get labelMember;

  /// No description provided for @labelNotes.
  ///
  /// In hr, this message translates to:
  /// **'Napomena'**
  String get labelNotes;

  /// No description provided for @notificationsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Obavijesti'**
  String get notificationsTitle;

  /// No description provided for @logoutTitle.
  ///
  /// In hr, this message translates to:
  /// **'Odjava'**
  String get logoutTitle;

  /// No description provided for @logoutTooltip.
  ///
  /// In hr, this message translates to:
  /// **'Odjavi se'**
  String get logoutTooltip;

  /// No description provided for @logoutQuestion.
  ///
  /// In hr, this message translates to:
  /// **'Želiš li se odjaviti iz aplikacije?'**
  String get logoutQuestion;

  /// No description provided for @logoutAction.
  ///
  /// In hr, this message translates to:
  /// **'Odjavi se'**
  String get logoutAction;

  /// No description provided for @logoutInProgress.
  ///
  /// In hr, this message translates to:
  /// **'Odjavljujem...'**
  String get logoutInProgress;

  /// No description provided for @loginSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Prijavi se u svoj studio'**
  String get loginSubtitle;

  /// No description provided for @loginAction.
  ///
  /// In hr, this message translates to:
  /// **'Prijavi se'**
  String get loginAction;

  /// No description provided for @loginInProgress.
  ///
  /// In hr, this message translates to:
  /// **'Prijava...'**
  String get loginInProgress;

  /// No description provided for @loginSuccess.
  ///
  /// In hr, this message translates to:
  /// **'Prijava je uspješna.'**
  String get loginSuccess;

  /// No description provided for @showPassword.
  ///
  /// In hr, this message translates to:
  /// **'Prikaži lozinku'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In hr, this message translates to:
  /// **'Sakrij lozinku'**
  String get hidePassword;

  /// No description provided for @invalidEmail.
  ///
  /// In hr, this message translates to:
  /// **'Unesi ispravnu e-mail adresu.'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesi lozinku.'**
  String get passwordRequired;

  /// No description provided for @profileMyPlan.
  ///
  /// In hr, this message translates to:
  /// **'Moj paket'**
  String get profileMyPlan;

  /// No description provided for @profileValid.
  ///
  /// In hr, this message translates to:
  /// **'Vrijedi'**
  String get profileValid;

  /// No description provided for @profileValidFrom.
  ///
  /// In hr, this message translates to:
  /// **'Od {date}'**
  String profileValidFrom(String date);

  /// No description provided for @profileValidRange.
  ///
  /// In hr, this message translates to:
  /// **'{start} – {end}'**
  String profileValidRange(String start, String end);

  /// No description provided for @profileUsedThisWeek.
  ///
  /// In hr, this message translates to:
  /// **'Iskorišteno ovaj tjedan'**
  String get profileUsedThisWeek;

  /// No description provided for @profileUsedThisMonth.
  ///
  /// In hr, this message translates to:
  /// **'Iskorišteno ovaj mjesec'**
  String get profileUsedThisMonth;

  /// No description provided for @profileUsedInMembership.
  ///
  /// In hr, this message translates to:
  /// **'Iskorišteno u članarini'**
  String get profileUsedInMembership;

  /// No description provided for @profileUsedInBillingCycle.
  ///
  /// In hr, this message translates to:
  /// **'Iskorišteno u obračunskom periodu'**
  String get profileUsedInBillingCycle;

  /// No description provided for @profileMembersProgress.
  ///
  /// In hr, this message translates to:
  /// **'Antropometrija članova'**
  String get profileMembersProgress;

  /// No description provided for @profileMembersProgressSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Pregled i unos mjerenja'**
  String get profileMembersProgressSubtitle;

  /// No description provided for @profileMyPayments.
  ///
  /// In hr, this message translates to:
  /// **'Moja članarina'**
  String get profileMyPayments;

  /// No description provided for @profileAdminPayments.
  ///
  /// In hr, this message translates to:
  /// **'Naplata članarina'**
  String get profileAdminPayments;

  /// No description provided for @profileMyPaymentsSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Podaci za uplatu i povijest'**
  String get profileMyPaymentsSubtitle;

  /// No description provided for @profileAdminPaymentsSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Pregled i potvrda uplata'**
  String get profileAdminPaymentsSubtitle;

  /// No description provided for @profilePaymentSettings.
  ///
  /// In hr, this message translates to:
  /// **'Postavke plaćanja'**
  String get profilePaymentSettings;

  /// No description provided for @profilePaymentSettingsSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Primatelj, IBAN i podaci za uplatu'**
  String get profilePaymentSettingsSubtitle;

  /// No description provided for @profileAnthropometry.
  ///
  /// In hr, this message translates to:
  /// **'Antropometrija'**
  String get profileAnthropometry;

  /// No description provided for @profileAnthropometrySubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Tjelesna mjerenja'**
  String get profileAnthropometrySubtitle;

  /// No description provided for @profileFixedSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Fiksni termini'**
  String get profileFixedSchedules;

  /// No description provided for @profileAboutMe.
  ///
  /// In hr, this message translates to:
  /// **'O meni'**
  String get profileAboutMe;

  /// No description provided for @roleAdmin.
  ///
  /// In hr, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleTrainer.
  ///
  /// In hr, this message translates to:
  /// **'Trener'**
  String get roleTrainer;

  /// No description provided for @roleMember.
  ///
  /// In hr, this message translates to:
  /// **'Član'**
  String get roleMember;

  /// No description provided for @statusActive.
  ///
  /// In hr, this message translates to:
  /// **'Aktivan'**
  String get statusActive;

  /// No description provided for @statusPaused.
  ///
  /// In hr, this message translates to:
  /// **'Pauziran'**
  String get statusPaused;

  /// No description provided for @statusInactive.
  ///
  /// In hr, this message translates to:
  /// **'Neaktivan'**
  String get statusInactive;

  /// No description provided for @statusCompleted.
  ///
  /// In hr, this message translates to:
  /// **'Završeno'**
  String get statusCompleted;

  /// No description provided for @unknownDay.
  ///
  /// In hr, this message translates to:
  /// **'Dan {day}'**
  String unknownDay(int day);

  /// No description provided for @classSessionsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Termini'**
  String get classSessionsTitle;

  /// No description provided for @schedulesTooltip.
  ///
  /// In hr, this message translates to:
  /// **'Upravljaj rasporedima'**
  String get schedulesTooltip;

  /// No description provided for @noClassSessionsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Nema termina'**
  String get noClassSessionsTitle;

  /// No description provided for @noClassSessionsMessage.
  ///
  /// In hr, this message translates to:
  /// **'Trenutno nema raspisanih grupnih treninga.'**
  String get noClassSessionsMessage;

  /// No description provided for @spotsAvailable.
  ///
  /// In hr, this message translates to:
  /// **'{count, plural, =1{1 mjesto} few{{count} mjesta} other{{count} mjesta}}'**
  String spotsAvailable(int count);

  /// No description provided for @classFull.
  ///
  /// In hr, this message translates to:
  /// **'Popunjeno'**
  String get classFull;

  /// No description provided for @previousWeek.
  ///
  /// In hr, this message translates to:
  /// **'Prethodni tjedan'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In hr, this message translates to:
  /// **'Sljedeći tjedan'**
  String get nextWeek;

  /// No description provided for @sessionsCount.
  ///
  /// In hr, this message translates to:
  /// **'{count, plural, =0{nema termina} =1{1 termin} few{{count} termina} other{{count} termina}}'**
  String sessionsCount(int count);

  /// No description provided for @daySessionsSemantics.
  ///
  /// In hr, this message translates to:
  /// **'{day}, {date}, {count, plural, =0{nema termina} =1{1 termin} few{{count} termina} other{{count} termina}}'**
  String daySessionsSemantics(String day, String date, int count);

  /// No description provided for @classSessionDetailsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Detalji termina'**
  String get classSessionDetailsTitle;

  /// No description provided for @minutesShort.
  ///
  /// In hr, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @labelBookingAvailability.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija'**
  String get labelBookingAvailability;

  /// No description provided for @bookingAvailable.
  ///
  /// In hr, this message translates to:
  /// **'Dostupna'**
  String get bookingAvailable;

  /// No description provided for @bookingUnavailable.
  ///
  /// In hr, this message translates to:
  /// **'Nije dostupna'**
  String get bookingUnavailable;

  /// No description provided for @occupancyTitle.
  ///
  /// In hr, this message translates to:
  /// **'Popunjenost'**
  String get occupancyTitle;

  /// No description provided for @reservedCapacity.
  ///
  /// In hr, this message translates to:
  /// **'{booked}/{capacity} rezervirano'**
  String reservedCapacity(int booked, int capacity);

  /// No description provided for @freeSpots.
  ///
  /// In hr, this message translates to:
  /// **'{count, plural, =1{1 mjesto slobodno} few{{count} mjesta slobodno} other{{count} mjesta slobodno}}'**
  String freeSpots(int count);

  /// No description provided for @classIsFull.
  ///
  /// In hr, this message translates to:
  /// **'Termin je pun'**
  String get classIsFull;

  /// No description provided for @bookAction.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviraj'**
  String get bookAction;

  /// No description provided for @bookingInProgress.
  ///
  /// In hr, this message translates to:
  /// **'Rezerviram...'**
  String get bookingInProgress;

  /// No description provided for @bookingSaved.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacija je spremljena.'**
  String get bookingSaved;

  /// No description provided for @cancelSessionTitle.
  ///
  /// In hr, this message translates to:
  /// **'Otkaži termin'**
  String get cancelSessionTitle;

  /// No description provided for @cancelSessionAction.
  ///
  /// In hr, this message translates to:
  /// **'Otkaži termin'**
  String get cancelSessionAction;

  /// No description provided for @cancelOnlyThisSession.
  ///
  /// In hr, this message translates to:
  /// **'Otkaži ovaj termin'**
  String get cancelOnlyThisSession;

  /// No description provided for @cancelOnlyThisSessionQuestion.
  ///
  /// In hr, this message translates to:
  /// **'Želiš li otkazati samo ovaj termin? Budući termini iz rasporeda ostat će aktivni.'**
  String get cancelOnlyThisSessionQuestion;

  /// No description provided for @cancellingSession.
  ///
  /// In hr, this message translates to:
  /// **'Otkazujem...'**
  String get cancellingSession;

  /// No description provided for @sessionCancelled.
  ///
  /// In hr, this message translates to:
  /// **'Termin je otkazan.'**
  String get sessionCancelled;

  /// No description provided for @loggedUserNotMember.
  ///
  /// In hr, this message translates to:
  /// **'Prijavljeni korisnik nije povezan s članom.'**
  String get loggedUserNotMember;

  /// No description provided for @pauseSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Pauziraj raspored'**
  String get pauseSchedule;

  /// No description provided for @resumeSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Nastavi raspored'**
  String get resumeSchedule;

  /// No description provided for @finishSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Završi raspored'**
  String get finishSchedule;

  /// No description provided for @pauseAction.
  ///
  /// In hr, this message translates to:
  /// **'Pauziraj'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In hr, this message translates to:
  /// **'Nastavi'**
  String get resumeAction;

  /// No description provided for @finishAction.
  ///
  /// In hr, this message translates to:
  /// **'Završi'**
  String get finishAction;

  /// No description provided for @pauseScheduleMessage.
  ///
  /// In hr, this message translates to:
  /// **'Od odabranog datuma otkazat će se ovaj i svi budući termini rasporeda. Raspored se kasnije može nastaviti.'**
  String get pauseScheduleMessage;

  /// No description provided for @resumeScheduleMessage.
  ///
  /// In hr, this message translates to:
  /// **'Od odabranog datuma ponovno će se kreirati termini i rezervacije aktivnih fiksnih članova.'**
  String get resumeScheduleMessage;

  /// No description provided for @finishScheduleMessage.
  ///
  /// In hr, this message translates to:
  /// **'Od odabranog datuma raspored i povezane fiksne dodjele trajno završavaju. Ovu radnju nije moguće poništiti.'**
  String get finishScheduleMessage;

  /// No description provided for @schedulePaused.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je pauziran.'**
  String get schedulePaused;

  /// No description provided for @scheduleResumed.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je nastavljen.'**
  String get scheduleResumed;

  /// No description provided for @scheduleEnded.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je završen.'**
  String get scheduleEnded;

  /// No description provided for @attendeesTitle.
  ///
  /// In hr, this message translates to:
  /// **'Polaznici'**
  String get attendeesTitle;

  /// No description provided for @attendeesCapacity.
  ///
  /// In hr, this message translates to:
  /// **'Polaznici ({count}/{capacity})'**
  String attendeesCapacity(int count, int capacity);

  /// No description provided for @loadingAttendees.
  ///
  /// In hr, this message translates to:
  /// **'Učitavam polaznike...'**
  String get loadingAttendees;

  /// No description provided for @attendeesLoadError.
  ///
  /// In hr, this message translates to:
  /// **'Polaznike trenutno nije moguće učitati.'**
  String get attendeesLoadError;

  /// No description provided for @noAttendees.
  ///
  /// In hr, this message translates to:
  /// **'Nema prijavljenih polaznika.'**
  String get noAttendees;

  /// No description provided for @attendedTooltip.
  ///
  /// In hr, this message translates to:
  /// **'Prisutan'**
  String get attendedTooltip;

  /// No description provided for @noShowTooltip.
  ///
  /// In hr, this message translates to:
  /// **'Nije došao'**
  String get noShowTooltip;

  /// No description provided for @memberActionsTooltip.
  ///
  /// In hr, this message translates to:
  /// **'Akcije za člana'**
  String get memberActionsTooltip;

  /// No description provided for @removeFromSession.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni s ovog termina'**
  String get removeFromSession;

  /// No description provided for @removeFromFixedGroup.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni iz fiksne grupe'**
  String get removeFromFixedGroup;

  /// No description provided for @removeFromSessionShort.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni s termina'**
  String get removeFromSessionShort;

  /// No description provided for @removeFixedGroupWarning.
  ///
  /// In hr, this message translates to:
  /// **'Član će biti uklonjen s ovog i svih budućih termina iz ove fiksne grupe.'**
  String get removeFixedGroupWarning;

  /// No description provided for @removeSessionWarning.
  ///
  /// In hr, this message translates to:
  /// **'Član će biti uklonjen samo s ovog termina.'**
  String get removeSessionWarning;

  /// No description provided for @removedFromFixedGroup.
  ///
  /// In hr, this message translates to:
  /// **'Član je uklonjen iz fiksne grupe.'**
  String get removedFromFixedGroup;

  /// No description provided for @removedFromSession.
  ///
  /// In hr, this message translates to:
  /// **'Član je uklonjen s termina.'**
  String get removedFromSession;

  /// No description provided for @myWorkoutsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Moji treninzi'**
  String get myWorkoutsTitle;

  /// No description provided for @filterWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Filtriraj treninge'**
  String get filterWorkouts;

  /// No description provided for @filterActive.
  ///
  /// In hr, this message translates to:
  /// **'Aktivni'**
  String get filterActive;

  /// No description provided for @filterCompleted.
  ///
  /// In hr, this message translates to:
  /// **'Završeni'**
  String get filterCompleted;

  /// No description provided for @filterCancelled.
  ///
  /// In hr, this message translates to:
  /// **'Otkazani'**
  String get filterCancelled;

  /// No description provided for @filterAll.
  ///
  /// In hr, this message translates to:
  /// **'Svi'**
  String get filterAll;

  /// No description provided for @allTrainers.
  ///
  /// In hr, this message translates to:
  /// **'Svi treneri'**
  String get allTrainers;

  /// No description provided for @noReservedWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Nema rezerviranih treninga.'**
  String get noReservedWorkouts;

  /// No description provided for @noSessions.
  ///
  /// In hr, this message translates to:
  /// **'Nema termina.'**
  String get noSessions;

  /// No description provided for @cancelBookingDetails.
  ///
  /// In hr, this message translates to:
  /// **'{className}\n{date} u {time}'**
  String cancelBookingDetails(String className, String date, String time);

  /// No description provided for @bookingStatusAttended.
  ///
  /// In hr, this message translates to:
  /// **'Odrađeno'**
  String get bookingStatusAttended;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In hr, this message translates to:
  /// **'Nije došao'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In hr, this message translates to:
  /// **'Otkazano'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusLateCancelled.
  ///
  /// In hr, this message translates to:
  /// **'Kasni otkaz'**
  String get bookingStatusLateCancelled;

  /// No description provided for @bookingStatusWaitlisted.
  ///
  /// In hr, this message translates to:
  /// **'Lista čekanja'**
  String get bookingStatusWaitlisted;

  /// No description provided for @bookingStatusBooked.
  ///
  /// In hr, this message translates to:
  /// **'Rezervirano'**
  String get bookingStatusBooked;

  /// No description provided for @bookingSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Rezervacije'**
  String get bookingSettingsTitle;

  /// No description provided for @cancellationCutoffHoursLabel.
  ///
  /// In hr, this message translates to:
  /// **'Rok za povrat treninga (sati)'**
  String get cancellationCutoffHoursLabel;

  /// No description provided for @cancellationCutoffHoursDescription.
  ///
  /// In hr, this message translates to:
  /// **'Vrijednost od 0 do 168 sati prije početka treninga.'**
  String get cancellationCutoffHoursDescription;

  /// No description provided for @cancellationCutoffHoursValidation.
  ///
  /// In hr, this message translates to:
  /// **'Unesite cijeli broj od 0 do 168.'**
  String get cancellationCutoffHoursValidation;

  /// No description provided for @activeWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Aktivni treninzi'**
  String get activeWorkouts;

  /// No description provided for @completedWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Završeni treninzi'**
  String get completedWorkouts;

  /// No description provided for @cancelledWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Otkazani treninzi'**
  String get cancelledWorkouts;

  /// No description provided for @allWorkouts.
  ///
  /// In hr, this message translates to:
  /// **'Svi treninzi'**
  String get allWorkouts;

  /// No description provided for @attendeesCount.
  ///
  /// In hr, this message translates to:
  /// **'{count, plural, =1{1 polaznik} few{{count} polaznika} other{{count} polaznika}}'**
  String attendeesCount(int count);

  /// No description provided for @sessionStatusCancelled.
  ///
  /// In hr, this message translates to:
  /// **'Otkazan'**
  String get sessionStatusCancelled;

  /// No description provided for @sessionStatusCompleted.
  ///
  /// In hr, this message translates to:
  /// **'Završen'**
  String get sessionStatusCompleted;

  /// No description provided for @sessionStatusScheduled.
  ///
  /// In hr, this message translates to:
  /// **'Zakazan'**
  String get sessionStatusScheduled;

  /// No description provided for @progressTitle.
  ///
  /// In hr, this message translates to:
  /// **'Antropometrija'**
  String get progressTitle;

  /// No description provided for @measurementAction.
  ///
  /// In hr, this message translates to:
  /// **'Mjerenje'**
  String get measurementAction;

  /// No description provided for @noMemberProfileTitle.
  ///
  /// In hr, this message translates to:
  /// **'Nema članskog profila'**
  String get noMemberProfileTitle;

  /// No description provided for @noMemberProfileMessage.
  ///
  /// In hr, this message translates to:
  /// **'Antropometrijska mjerenja dostupna su članovima.'**
  String get noMemberProfileMessage;

  /// No description provided for @noMeasurementsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Nema mjerenja'**
  String get noMeasurementsTitle;

  /// No description provided for @noMeasurementsMessage.
  ///
  /// In hr, this message translates to:
  /// **'Još nema zabilježenih antropometrijskih mjerenja.'**
  String get noMeasurementsMessage;

  /// No description provided for @parameterLabel.
  ///
  /// In hr, this message translates to:
  /// **'Parametar'**
  String get parameterLabel;

  /// No description provided for @currentValue.
  ///
  /// In hr, this message translates to:
  /// **'Trenutno'**
  String get currentValue;

  /// No description provided for @chartNeedsTwoMeasurements.
  ///
  /// In hr, this message translates to:
  /// **'Za graf su potrebna barem dva mjerenja.'**
  String get chartNeedsTwoMeasurements;

  /// No description provided for @progressTrend.
  ///
  /// In hr, this message translates to:
  /// **'Kretanje'**
  String get progressTrend;

  /// No description provided for @progressHistory.
  ///
  /// In hr, this message translates to:
  /// **'Povijest'**
  String get progressHistory;

  /// No description provided for @membersProgressTitle.
  ///
  /// In hr, this message translates to:
  /// **'Antropometrija članova'**
  String get membersProgressTitle;

  /// No description provided for @searchMembers.
  ///
  /// In hr, this message translates to:
  /// **'Pretraži članove'**
  String get searchMembers;

  /// No description provided for @noMembersFound.
  ///
  /// In hr, this message translates to:
  /// **'Nema pronađenih članova.'**
  String get noMembersFound;

  /// No description provided for @newMeasurementTitle.
  ///
  /// In hr, this message translates to:
  /// **'Novo mjerenje'**
  String get newMeasurementTitle;

  /// No description provided for @enterOneMeasuredParameter.
  ///
  /// In hr, this message translates to:
  /// **'Unesi barem jedan izmjereni parametar.'**
  String get enterOneMeasuredParameter;

  /// No description provided for @saveMeasurement.
  ///
  /// In hr, this message translates to:
  /// **'Spremi mjerenje'**
  String get saveMeasurement;

  /// No description provided for @invalidNumber.
  ///
  /// In hr, this message translates to:
  /// **'Unesi ispravan broj.'**
  String get invalidNumber;

  /// No description provided for @enterOneValue.
  ///
  /// In hr, this message translates to:
  /// **'Unesi barem jednu vrijednost.'**
  String get enterOneValue;

  /// No description provided for @newScheduleTitle.
  ///
  /// In hr, this message translates to:
  /// **'Novi raspored'**
  String get newScheduleTitle;

  /// No description provided for @recurringScheduleDescription.
  ///
  /// In hr, this message translates to:
  /// **'Termin će se ponavljati svaki tjedan od odabranog datuma.'**
  String get recurringScheduleDescription;

  /// No description provided for @missingClassTypesOrTrainers.
  ///
  /// In hr, this message translates to:
  /// **'Nedostaju vrste treninga ili treneri.'**
  String get missingClassTypesOrTrainers;

  /// No description provided for @classTypeLabel.
  ///
  /// In hr, this message translates to:
  /// **'Vrsta treninga'**
  String get classTypeLabel;

  /// No description provided for @dayLabel.
  ///
  /// In hr, this message translates to:
  /// **'Dan'**
  String get dayLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In hr, this message translates to:
  /// **'Vrijeme početka'**
  String get startTimeLabel;

  /// No description provided for @durationMinutesLabel.
  ///
  /// In hr, this message translates to:
  /// **'Trajanje (min)'**
  String get durationMinutesLabel;

  /// No description provided for @positiveNumberRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesi broj veći od 0.'**
  String get positiveNumberRequired;

  /// No description provided for @validFromLabel.
  ///
  /// In hr, this message translates to:
  /// **'Vrijedi od'**
  String get validFromLabel;

  /// No description provided for @saveSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Spremi raspored'**
  String get saveSchedule;

  /// No description provided for @scheduleCreated.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je spremljen.'**
  String get scheduleCreated;

  /// No description provided for @schedulesTitle.
  ///
  /// In hr, this message translates to:
  /// **'Rasporedi'**
  String get schedulesTitle;

  /// No description provided for @filterSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Filtriraj rasporede'**
  String get filterSchedules;

  /// No description provided for @scheduleFixedOccupancy.
  ///
  /// In hr, this message translates to:
  /// **'{active}/{capacity} članova'**
  String scheduleFixedOccupancy(int active, int capacity);

  /// No description provided for @noSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Nema kreiranih rasporeda.'**
  String get noSchedules;

  /// No description provided for @activeSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Aktivni'**
  String get activeSchedules;

  /// No description provided for @pausedSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Pauzirani'**
  String get pausedSchedules;

  /// No description provided for @completedSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Završeni'**
  String get completedSchedules;

  /// No description provided for @manageSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Upravljaj rasporedom'**
  String get manageSchedule;

  /// No description provided for @effectiveFromDate.
  ///
  /// In hr, this message translates to:
  /// **'od {date}'**
  String effectiveFromDate(String date);

  /// No description provided for @paymentSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Postavke plaćanja'**
  String get paymentSettingsTitle;

  /// No description provided for @recipientLabel.
  ///
  /// In hr, this message translates to:
  /// **'Primatelj'**
  String get recipientLabel;

  /// No description provided for @paymentModelLabel.
  ///
  /// In hr, this message translates to:
  /// **'Model'**
  String get paymentModelLabel;

  /// No description provided for @paymentReferenceLabel.
  ///
  /// In hr, this message translates to:
  /// **'Poziv na broj'**
  String get paymentReferenceLabel;

  /// No description provided for @paymentDescriptionLabel.
  ///
  /// In hr, this message translates to:
  /// **'Opis plaćanja'**
  String get paymentDescriptionLabel;

  /// No description provided for @memberReminderDaysLabel.
  ///
  /// In hr, this message translates to:
  /// **'Podsjetnici članu (dani nakon dospijeća)'**
  String get memberReminderDaysLabel;

  /// No description provided for @adminReminderDaysLabel.
  ///
  /// In hr, this message translates to:
  /// **'Podsjetnici adminu'**
  String get adminReminderDaysLabel;

  /// No description provided for @sendTimeLabel.
  ///
  /// In hr, this message translates to:
  /// **'Vrijeme slanja (HH:mm)'**
  String get sendTimeLabel;

  /// No description provided for @requiredField.
  ///
  /// In hr, this message translates to:
  /// **'Ovo polje je obvezno.'**
  String get requiredField;

  /// No description provided for @settingsSaved.
  ///
  /// In hr, this message translates to:
  /// **'Postavke su spremljene.'**
  String get settingsSaved;

  /// No description provided for @noPaymentsInCategory.
  ///
  /// In hr, this message translates to:
  /// **'Nema obračuna u ovoj kategoriji.'**
  String get noPaymentsInCategory;

  /// No description provided for @paymentFilterPending.
  ///
  /// In hr, this message translates to:
  /// **'Za naplatu'**
  String get paymentFilterPending;

  /// No description provided for @paymentFilterReported.
  ///
  /// In hr, this message translates to:
  /// **'Čeka potvrdu'**
  String get paymentFilterReported;

  /// No description provided for @paymentFilterOverdue.
  ///
  /// In hr, this message translates to:
  /// **'Kasni'**
  String get paymentFilterOverdue;

  /// No description provided for @paymentFilterPaid.
  ///
  /// In hr, this message translates to:
  /// **'Plaćeno'**
  String get paymentFilterPaid;

  /// No description provided for @paymentFilterAll.
  ///
  /// In hr, this message translates to:
  /// **'Sve'**
  String get paymentFilterAll;

  /// No description provided for @paymentRecipient.
  ///
  /// In hr, this message translates to:
  /// **'Primatelj'**
  String get paymentRecipient;

  /// No description provided for @paymentModelAndReference.
  ///
  /// In hr, this message translates to:
  /// **'Model i poziv'**
  String get paymentModelAndReference;

  /// No description provided for @paymentDescription.
  ///
  /// In hr, this message translates to:
  /// **'Opis'**
  String get paymentDescription;

  /// No description provided for @paymentDueSummary.
  ///
  /// In hr, this message translates to:
  /// **'{plan} · {period}\n{amount} · {status} · dospijeće {dueDate}'**
  String paymentDueSummary(
    String plan,
    String period,
    String amount,
    String status,
    String dueDate,
  );

  /// No description provided for @paymentStatusUnpaid.
  ///
  /// In hr, this message translates to:
  /// **'Neplaćeno'**
  String get paymentStatusUnpaid;

  /// No description provided for @paymentCode.
  ///
  /// In hr, this message translates to:
  /// **'Kod za plaćanje'**
  String get paymentCode;

  /// No description provided for @paymentReported.
  ///
  /// In hr, this message translates to:
  /// **'Uplatio sam'**
  String get paymentReported;

  /// No description provided for @rejectPaymentReport.
  ///
  /// In hr, this message translates to:
  /// **'Odbij prijavu'**
  String get rejectPaymentReport;

  /// No description provided for @reopenPayment.
  ///
  /// In hr, this message translates to:
  /// **'Ponovno otvori'**
  String get reopenPayment;

  /// No description provided for @endMembership.
  ///
  /// In hr, this message translates to:
  /// **'Završi članstvo'**
  String get endMembership;

  /// No description provided for @endMembershipSummary.
  ///
  /// In hr, this message translates to:
  /// **'Prvi dan kada više ne treniram: {date}\nProcijenjeni zadnji iznos: {amount}'**
  String endMembershipSummary(String date, String amount);

  /// No description provided for @markPaid.
  ///
  /// In hr, this message translates to:
  /// **'Označi plaćeno'**
  String get markPaid;

  /// No description provided for @changeSaved.
  ///
  /// In hr, this message translates to:
  /// **'Promjena je spremljena.'**
  String get changeSaved;

  /// No description provided for @hub3PaymentCode.
  ///
  /// In hr, this message translates to:
  /// **'HUB3 kod za plaćanje'**
  String get hub3PaymentCode;

  /// No description provided for @billingNotEnabled.
  ///
  /// In hr, this message translates to:
  /// **'Naplata nije uključena'**
  String get billingNotEnabled;

  /// No description provided for @allMembershipsBillingEnabled.
  ///
  /// In hr, this message translates to:
  /// **'Sva aktivna članstva imaju uključenu naplatu.'**
  String get allMembershipsBillingEnabled;

  /// No description provided for @enableBilling.
  ///
  /// In hr, this message translates to:
  /// **'Uključi naplatu'**
  String get enableBilling;

  /// No description provided for @activeBilling.
  ///
  /// In hr, this message translates to:
  /// **'Aktivna naplata'**
  String get activeBilling;

  /// No description provided for @noActiveBilling.
  ///
  /// In hr, this message translates to:
  /// **'Nema članstava s aktivnom naplatom.'**
  String get noActiveBilling;

  /// No description provided for @membershipStarted.
  ///
  /// In hr, this message translates to:
  /// **'Početak članstva: {date}'**
  String membershipStarted(String date);

  /// No description provided for @billingValidFrom.
  ///
  /// In hr, this message translates to:
  /// **'Naplata vrijedi od'**
  String get billingValidFrom;

  /// No description provided for @retroactiveBilling.
  ///
  /// In hr, this message translates to:
  /// **'Retroaktivna naplata'**
  String get retroactiveBilling;

  /// No description provided for @billingStartsSummary.
  ///
  /// In hr, this message translates to:
  /// **'{plan}\nNaplata vrijedi od: {start}\nSljedeći obračun: {next}'**
  String billingStartsSummary(String plan, String start, String next);

  /// No description provided for @retroactiveBillingWarning.
  ///
  /// In hr, this message translates to:
  /// **'Odabrali ste {date}. Odmah će nastati sve mjesečne obveze od tog datuma do aktualnog ciklusa.'**
  String retroactiveBillingWarning(String date);

  /// No description provided for @billingEnabled.
  ///
  /// In hr, this message translates to:
  /// **'Naplata je uključena.'**
  String get billingEnabled;

  /// No description provided for @billingEnabledWithCount.
  ///
  /// In hr, this message translates to:
  /// **'Naplata je uključena. {count, plural, =1{Kreiran je 1 obračun.} few{Kreirana su {count} obračuna.} other{Kreirano je {count} obračuna.}}'**
  String billingEnabledWithCount(int count);

  /// No description provided for @noNextBilling.
  ///
  /// In hr, this message translates to:
  /// **'nema'**
  String get noNextBilling;

  /// No description provided for @failureRestoreSession.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće učitati spremljenu prijavu.'**
  String get failureRestoreSession;

  /// No description provided for @failureLogout.
  ///
  /// In hr, this message translates to:
  /// **'Odjava trenutno nije moguća. Pokušaj ponovno.'**
  String get failureLogout;

  /// No description provided for @failureLoginResponse.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati odgovor za prijavu.'**
  String get failureLoginResponse;

  /// No description provided for @failureSaveSession.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće sigurno spremiti prijavu.'**
  String get failureSaveSession;

  /// No description provided for @failureReadApi.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati podatke s API-ja.'**
  String get failureReadApi;

  /// No description provided for @failureReadBookings.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati rezervacije.'**
  String get failureReadBookings;

  /// No description provided for @failureReadTrainers.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati trenere.'**
  String get failureReadTrainers;

  /// No description provided for @failureReadSchedules.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati rasporede.'**
  String get failureReadSchedules;

  /// No description provided for @failureReadScheduleForm.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati podatke za novi termin.'**
  String get failureReadScheduleForm;

  /// No description provided for @failureReadScheduleResponse.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati odgovor za novi termin.'**
  String get failureReadScheduleResponse;

  /// No description provided for @failureReadProgress.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće pročitati antropometrijska mjerenja.'**
  String get failureReadProgress;

  /// No description provided for @failureReadMembers.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće učitati članove.'**
  String get failureReadMembers;

  /// No description provided for @failureReadMeasurementParameters.
  ///
  /// In hr, this message translates to:
  /// **'Nije moguće učitati parametre mjerenja.'**
  String get failureReadMeasurementParameters;

  /// No description provided for @failureSaveMeasurement.
  ///
  /// In hr, this message translates to:
  /// **'Mjerenje nije moguće spremiti.'**
  String get failureSaveMeasurement;

  /// No description provided for @failureBookingAlreadyExists.
  ///
  /// In hr, this message translates to:
  /// **'Već ste prijavljeni na ovaj termin.'**
  String get failureBookingAlreadyExists;

  /// No description provided for @failureMembershipRequired.
  ///
  /// In hr, this message translates to:
  /// **'Nemate paket koji vrijedi na datum ovog termina.'**
  String get failureMembershipRequired;

  /// No description provided for @failureMembershipLimitReached.
  ///
  /// In hr, this message translates to:
  /// **'Iskoristili ste sve termine dostupne u paketu za ovo razdoblje.'**
  String get failureMembershipLimitReached;

  /// No description provided for @failureNotFound.
  ///
  /// In hr, this message translates to:
  /// **'Traženi podatak nije pronađen.'**
  String get failureNotFound;

  /// No description provided for @failureNetwork.
  ///
  /// In hr, this message translates to:
  /// **'Mrežni zahtjev nije uspio.'**
  String get failureNetwork;

  /// No description provided for @labelStudioCode.
  ///
  /// In hr, this message translates to:
  /// **'Kod studija'**
  String get labelStudioCode;

  /// No description provided for @studioCodeRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesi kod studija.'**
  String get studioCodeRequired;

  /// No description provided for @trainersTitle.
  ///
  /// In hr, this message translates to:
  /// **'Treneri'**
  String get trainersTitle;

  /// No description provided for @trainerManagementSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj i uređuj trenere'**
  String get trainerManagementSubtitle;

  /// No description provided for @membershipPlansTitle.
  ///
  /// In hr, this message translates to:
  /// **'Cjenik'**
  String get membershipPlansTitle;

  /// No description provided for @membershipPlansSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Upravljaj cjenikom'**
  String get membershipPlansSubtitle;

  /// No description provided for @memberPackagesTitle.
  ///
  /// In hr, this message translates to:
  /// **'Članovi i paketi'**
  String get memberPackagesTitle;

  /// No description provided for @memberPackagesSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Dodijeli ili promijeni paket članu'**
  String get memberPackagesSubtitle;

  /// No description provided for @memberPackagesFilterAll.
  ///
  /// In hr, this message translates to:
  /// **'Svi članovi'**
  String get memberPackagesFilterAll;

  /// No description provided for @memberPackagesFilterMissing.
  ///
  /// In hr, this message translates to:
  /// **'Bez paketa ({count})'**
  String memberPackagesFilterMissing(int count);

  /// No description provided for @memberPackageMissing.
  ///
  /// In hr, this message translates to:
  /// **'Nema aktivnog paketa'**
  String get memberPackageMissing;

  /// No description provided for @memberPackageFrom.
  ///
  /// In hr, this message translates to:
  /// **'Vrijedi od {start}'**
  String memberPackageFrom(String start);

  /// No description provided for @memberPackagePeriod.
  ///
  /// In hr, this message translates to:
  /// **'{start} – {end}'**
  String memberPackagePeriod(String start, String end);

  /// No description provided for @memberPackageInactiveMemberHint.
  ///
  /// In hr, this message translates to:
  /// **'Pakete nije moguće mijenjati neaktivnom članu.'**
  String get memberPackageInactiveMemberHint;

  /// No description provided for @assignMemberPackage.
  ///
  /// In hr, this message translates to:
  /// **'Dodijeli paket'**
  String get assignMemberPackage;

  /// No description provided for @changeMemberPackage.
  ///
  /// In hr, this message translates to:
  /// **'Promijeni paket'**
  String get changeMemberPackage;

  /// No description provided for @assignPackageTo.
  ///
  /// In hr, this message translates to:
  /// **'Dodijeli paket: {memberName}'**
  String assignPackageTo(String memberName);

  /// No description provided for @changePackageFor.
  ///
  /// In hr, this message translates to:
  /// **'Promijeni paket: {memberName}'**
  String changePackageFor(String memberName);

  /// No description provided for @memberPackageStartsOn.
  ///
  /// In hr, this message translates to:
  /// **'Početak članstva'**
  String get memberPackageStartsOn;

  /// No description provided for @memberPackageEndsOn.
  ///
  /// In hr, this message translates to:
  /// **'Kraj članstva'**
  String get memberPackageEndsOn;

  /// No description provided for @memberPackageNoEndDate.
  ///
  /// In hr, this message translates to:
  /// **'Bez datuma završetka'**
  String get memberPackageNoEndDate;

  /// No description provided for @memberPackageClearEnd.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni datum završetka'**
  String get memberPackageClearEnd;

  /// No description provided for @memberPackagePlanRequired.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi paket.'**
  String get memberPackagePlanRequired;

  /// No description provided for @memberPackageEndAfterStart.
  ///
  /// In hr, this message translates to:
  /// **'Datum završetka mora biti nakon datuma početka.'**
  String get memberPackageEndAfterStart;

  /// No description provided for @memberPackageOverlap.
  ///
  /// In hr, this message translates to:
  /// **'Član već ima paket koji se preklapa s odabranim razdobljem.'**
  String get memberPackageOverlap;

  /// No description provided for @noActiveMembershipPlans.
  ///
  /// In hr, this message translates to:
  /// **'Nema aktivnih paketa koje je moguće dodijeliti.'**
  String get noActiveMembershipPlans;

  /// No description provided for @memberPackageSaved.
  ///
  /// In hr, this message translates to:
  /// **'Paket za člana {memberName} je spremljen.'**
  String memberPackageSaved(String memberName);

  /// No description provided for @addMembershipPlan.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj paket'**
  String get addMembershipPlan;

  /// No description provided for @editMembershipPlan.
  ///
  /// In hr, this message translates to:
  /// **'Uredi paket'**
  String get editMembershipPlan;

  /// No description provided for @noMembershipPlans.
  ///
  /// In hr, this message translates to:
  /// **'Još nema paketa.'**
  String get noMembershipPlans;

  /// No description provided for @membershipPlanName.
  ///
  /// In hr, this message translates to:
  /// **'Naziv paketa'**
  String get membershipPlanName;

  /// No description provided for @membershipPlanDescription.
  ///
  /// In hr, this message translates to:
  /// **'Opis'**
  String get membershipPlanDescription;

  /// No description provided for @membershipPlanPrice.
  ///
  /// In hr, this message translates to:
  /// **'Mjesečna cijena'**
  String get membershipPlanPrice;

  /// No description provided for @membershipPlanLimitEnabled.
  ///
  /// In hr, this message translates to:
  /// **'Ograniči broj termina'**
  String get membershipPlanLimitEnabled;

  /// No description provided for @membershipPlanSessionLimit.
  ///
  /// In hr, this message translates to:
  /// **'Broj termina'**
  String get membershipPlanSessionLimit;

  /// No description provided for @membershipPlanLimitPeriod.
  ///
  /// In hr, this message translates to:
  /// **'Razdoblje ograničenja'**
  String get membershipPlanLimitPeriod;

  /// No description provided for @membershipPlanPeriodWeek.
  ///
  /// In hr, this message translates to:
  /// **'Tjedan'**
  String get membershipPlanPeriodWeek;

  /// No description provided for @membershipPlanPeriodMonth.
  ///
  /// In hr, this message translates to:
  /// **'Mjesec'**
  String get membershipPlanPeriodMonth;

  /// No description provided for @membershipPlanPeriodMembership.
  ///
  /// In hr, this message translates to:
  /// **'Članstvo'**
  String get membershipPlanPeriodMembership;

  /// No description provided for @membershipPlanUnlimited.
  ///
  /// In hr, this message translates to:
  /// **'Neograničen broj termina'**
  String get membershipPlanUnlimited;

  /// No description provided for @membershipPlanMonthlyPrice.
  ///
  /// In hr, this message translates to:
  /// **'{price} mjesečno'**
  String membershipPlanMonthlyPrice(String price);

  /// No description provided for @membershipPlanLimitSummary.
  ///
  /// In hr, this message translates to:
  /// **'{count} termina / {period}'**
  String membershipPlanLimitSummary(int count, String period);

  /// No description provided for @membershipPlanActive.
  ///
  /// In hr, this message translates to:
  /// **'Aktivan paket'**
  String get membershipPlanActive;

  /// No description provided for @deleteMembershipPlanTitle.
  ///
  /// In hr, this message translates to:
  /// **'Obriši paket?'**
  String get deleteMembershipPlanTitle;

  /// No description provided for @deleteMembershipPlanQuestion.
  ///
  /// In hr, this message translates to:
  /// **'Paket {name} bit će trajno obrisan.'**
  String deleteMembershipPlanQuestion(String name);

  /// No description provided for @membershipPlanCreated.
  ///
  /// In hr, this message translates to:
  /// **'Paket je dodan.'**
  String get membershipPlanCreated;

  /// No description provided for @membershipPlanUpdated.
  ///
  /// In hr, this message translates to:
  /// **'Paket je spremljen.'**
  String get membershipPlanUpdated;

  /// No description provided for @membershipPlanDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Paket je obrisan.'**
  String get membershipPlanDeleted;

  /// No description provided for @membershipPlanCannotDeleteTitle.
  ///
  /// In hr, this message translates to:
  /// **'Paket se ne može obrisati'**
  String get membershipPlanCannotDeleteTitle;

  /// No description provided for @membershipPlanCannotDeleteMessage.
  ///
  /// In hr, this message translates to:
  /// **'Paket je povezan s postojećim članstvima. Možeš ga označiti neaktivnim.'**
  String get membershipPlanCannotDeleteMessage;

  /// No description provided for @deactivateMembershipPlan.
  ///
  /// In hr, this message translates to:
  /// **'Označi neaktivnim'**
  String get deactivateMembershipPlan;

  /// No description provided for @membershipPlanDeactivated.
  ///
  /// In hr, this message translates to:
  /// **'Paket je označen neaktivnim.'**
  String get membershipPlanDeactivated;

  /// No description provided for @membershipPlanDuplicate.
  ///
  /// In hr, this message translates to:
  /// **'Paket s tim nazivom već postoji.'**
  String get membershipPlanDuplicate;

  /// No description provided for @invalidMembershipPlanPrice.
  ///
  /// In hr, this message translates to:
  /// **'Unesi ispravnu nenegativnu cijenu.'**
  String get invalidMembershipPlanPrice;

  /// No description provided for @invalidMembershipPlanLimit.
  ///
  /// In hr, this message translates to:
  /// **'Broj termina mora biti pozitivan cijeli broj.'**
  String get invalidMembershipPlanLimit;

  /// No description provided for @addTrainer.
  ///
  /// In hr, this message translates to:
  /// **'Novi trener'**
  String get addTrainer;

  /// No description provided for @editTrainer.
  ///
  /// In hr, this message translates to:
  /// **'Uredi trenera'**
  String get editTrainer;

  /// No description provided for @noTrainersYet.
  ///
  /// In hr, this message translates to:
  /// **'Još nema trenera.'**
  String get noTrainersYet;

  /// No description provided for @trainerCreated.
  ///
  /// In hr, this message translates to:
  /// **'Trener je dodan.'**
  String get trainerCreated;

  /// No description provided for @trainerUpdated.
  ///
  /// In hr, this message translates to:
  /// **'Trener je ažuriran.'**
  String get trainerUpdated;

  /// No description provided for @trainerDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Trener je obrisan.'**
  String get trainerDeleted;

  /// No description provided for @trainerDeactivated.
  ///
  /// In hr, this message translates to:
  /// **'Trener je označen neaktivnim.'**
  String get trainerDeactivated;

  /// No description provided for @deleteTrainerTitle.
  ///
  /// In hr, this message translates to:
  /// **'Obrisati trenera?'**
  String get deleteTrainerTitle;

  /// No description provided for @deleteTrainerQuestion.
  ///
  /// In hr, this message translates to:
  /// **'Želiš li obrisati trenera „{name}“?'**
  String deleteTrainerQuestion(String name);

  /// No description provided for @trainerCannotDeleteTitle.
  ///
  /// In hr, this message translates to:
  /// **'Trenera nije moguće obrisati'**
  String get trainerCannotDeleteTitle;

  /// No description provided for @trainerDeleteConflict.
  ///
  /// In hr, this message translates to:
  /// **'Trenera s povezanim terminima nije moguće ukloniti. Označi ga neaktivnim.'**
  String get trainerDeleteConflict;

  /// No description provided for @firstName.
  ///
  /// In hr, this message translates to:
  /// **'Ime'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In hr, this message translates to:
  /// **'Prezime'**
  String get lastName;

  /// No description provided for @phoneLabel.
  ///
  /// In hr, this message translates to:
  /// **'Telefon'**
  String get phoneLabel;

  /// No description provided for @bioLabel.
  ///
  /// In hr, this message translates to:
  /// **'Biografija'**
  String get bioLabel;

  /// No description provided for @saveAction.
  ///
  /// In hr, this message translates to:
  /// **'Spremi'**
  String get saveAction;

  /// No description provided for @registerTitle.
  ///
  /// In hr, this message translates to:
  /// **'Registracija'**
  String get registerTitle;

  /// No description provided for @registerAction.
  ///
  /// In hr, this message translates to:
  /// **'Kreiraj račun'**
  String get registerAction;

  /// No description provided for @passwordMinimumLength.
  ///
  /// In hr, this message translates to:
  /// **'Lozinka mora imati najmanje 10 znakova.'**
  String get passwordMinimumLength;

  /// No description provided for @chooseStudioTitle.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi studio'**
  String get chooseStudioTitle;

  /// No description provided for @yourStudios.
  ///
  /// In hr, this message translates to:
  /// **'Tvoji studiji'**
  String get yourStudios;

  /// No description provided for @joinStudioTitle.
  ///
  /// In hr, this message translates to:
  /// **'Pridruži se studiju'**
  String get joinStudioTitle;

  /// No description provided for @joinStudioConfirmation.
  ///
  /// In hr, this message translates to:
  /// **'Pridruživanje studiju {studioName}'**
  String joinStudioConfirmation(String studioName);

  /// No description provided for @checkStudioCode.
  ///
  /// In hr, this message translates to:
  /// **'Provjeri kod'**
  String get checkStudioCode;

  /// No description provided for @joinStudioAction.
  ///
  /// In hr, this message translates to:
  /// **'Pridruži se'**
  String get joinStudioAction;

  /// No description provided for @firstAndLastNameRequired.
  ///
  /// In hr, this message translates to:
  /// **'Unesi ime i prezime.'**
  String get firstAndLastNameRequired;

  /// No description provided for @profileCreated.
  ///
  /// In hr, this message translates to:
  /// **'Profil {displayName} je kreiran.'**
  String profileCreated(String displayName);

  /// No description provided for @changeOrAddStudio.
  ///
  /// In hr, this message translates to:
  /// **'Promijeni ili dodaj studio'**
  String get changeOrAddStudio;

  /// No description provided for @studioSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Postavke studija'**
  String get studioSettingsTitle;

  /// No description provided for @studioSettingsSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Pristup, naplata i podsjetnici'**
  String get studioSettingsSubtitle;

  /// No description provided for @studioAccessSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Pristup studiju'**
  String get studioAccessSettingsTitle;

  /// No description provided for @reminderSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Podsjetnici'**
  String get reminderSettingsTitle;

  /// No description provided for @allowJoinByCode.
  ///
  /// In hr, this message translates to:
  /// **'Dopusti povezivanje kodom'**
  String get allowJoinByCode;

  /// No description provided for @allowJoinByCodeDescription.
  ///
  /// In hr, this message translates to:
  /// **'Korisnici se mogu pridružiti unosom koda studija.'**
  String get allowJoinByCodeDescription;

  /// No description provided for @fixedScheduleMembers.
  ///
  /// In hr, this message translates to:
  /// **'Članovi'**
  String get fixedScheduleMembers;

  /// No description provided for @noFixedScheduleMembers.
  ///
  /// In hr, this message translates to:
  /// **'Ovaj raspored trenutačno nema članova u fiksnoj grupi.'**
  String get noFixedScheduleMembers;

  /// No description provided for @addFixedScheduleMember.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj člana'**
  String get addFixedScheduleMember;

  /// No description provided for @addFixedScheduleMemberAction.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj u fiksnu grupu'**
  String get addFixedScheduleMemberAction;

  /// No description provided for @fixedScheduleStartsOn.
  ///
  /// In hr, this message translates to:
  /// **'Početak fiksnog rasporeda'**
  String get fixedScheduleStartsOn;

  /// No description provided for @noMembersForFixedSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Nema dostupnih aktivnih članova.'**
  String get noMembersForFixedSchedule;

  /// No description provided for @fixedScheduleMemberAdded.
  ///
  /// In hr, this message translates to:
  /// **'{memberName} je dodan/a u fiksnu grupu.'**
  String fixedScheduleMemberAdded(String memberName);

  /// No description provided for @fixedScheduleInactiveMember.
  ///
  /// In hr, this message translates to:
  /// **'Samo aktivan član može biti dodan u fiksnu grupu.'**
  String get fixedScheduleInactiveMember;

  /// No description provided for @fixedScheduleInactiveSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Člana je moguće dodati samo u aktivan raspored.'**
  String get fixedScheduleInactiveSchedule;

  /// No description provided for @fixedScheduleAlreadyAssigned.
  ///
  /// In hr, this message translates to:
  /// **'Član je već dodan u ovaj fiksni raspored.'**
  String get fixedScheduleAlreadyAssigned;

  /// No description provided for @fixedScheduleFull.
  ///
  /// In hr, this message translates to:
  /// **'Fiksna grupa nema slobodnih mjesta.'**
  String get fixedScheduleFull;

  /// No description provided for @fixedScheduleChanged.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je u međuvremenu promijenjen. Pokušaj ponovno.'**
  String get fixedScheduleChanged;

  /// No description provided for @fixedSchedulePackageLimit.
  ///
  /// In hr, this message translates to:
  /// **'Paket člana ne dopušta dodatni fiksni termin.'**
  String get fixedSchedulePackageLimit;

  /// No description provided for @moveFixedScheduleMember.
  ///
  /// In hr, this message translates to:
  /// **'Premjesti'**
  String get moveFixedScheduleMember;

  /// No description provided for @selectMoveDestination.
  ///
  /// In hr, this message translates to:
  /// **'Odaberi novi raspored za {memberName}'**
  String selectMoveDestination(String memberName);

  /// No description provided for @cancelMove.
  ///
  /// In hr, this message translates to:
  /// **'Odustani od premještanja'**
  String get cancelMove;

  /// No description provided for @moveDestinationFull.
  ///
  /// In hr, this message translates to:
  /// **'Raspored je popunjen'**
  String get moveDestinationFull;

  /// No description provided for @moveMemberTitle.
  ///
  /// In hr, this message translates to:
  /// **'Premjesti člana?'**
  String get moveMemberTitle;

  /// No description provided for @moveMemberConfirmation.
  ///
  /// In hr, this message translates to:
  /// **'Jeste li sigurni da želite premjestiti {memberName} u {classType}, {weekday} u {time}?'**
  String moveMemberConfirmation(
    String memberName,
    String classType,
    String weekday,
    String time,
  );

  /// No description provided for @confirmMove.
  ///
  /// In hr, this message translates to:
  /// **'Premjesti'**
  String get confirmMove;

  /// No description provided for @fixedScheduleMemberMoved.
  ///
  /// In hr, this message translates to:
  /// **'Član je premješten u novi raspored.'**
  String get fixedScheduleMemberMoved;

  /// No description provided for @scheduleMembersLoadError.
  ///
  /// In hr, this message translates to:
  /// **'Članove fiksne grupe nije moguće učitati.'**
  String get scheduleMembersLoadError;

  /// No description provided for @editSchedule.
  ///
  /// In hr, this message translates to:
  /// **'Uredi raspored'**
  String get editSchedule;

  /// No description provided for @effectiveFromLabel.
  ///
  /// In hr, this message translates to:
  /// **'Promjena vrijedi od'**
  String get effectiveFromLabel;

  /// No description provided for @confirmScheduleUpdate.
  ///
  /// In hr, this message translates to:
  /// **'Spremi promjenu'**
  String get confirmScheduleUpdate;

  /// No description provided for @scheduleUpdated.
  ///
  /// In hr, this message translates to:
  /// **'Promjena rasporeda je spremljena.'**
  String get scheduleUpdated;

  /// No description provided for @scheduleValidFrom.
  ///
  /// In hr, this message translates to:
  /// **'Od {date}'**
  String scheduleValidFrom(String date);

  /// No description provided for @scheduleValidUntil.
  ///
  /// In hr, this message translates to:
  /// **'Do {date}'**
  String scheduleValidUntil(String date);

  /// No description provided for @studioAccessEnabledSummary.
  ///
  /// In hr, this message translates to:
  /// **'Povezivanje kodom je uključeno'**
  String get studioAccessEnabledSummary;

  /// No description provided for @studioAccessDisabledSummary.
  ///
  /// In hr, this message translates to:
  /// **'Povezivanje kodom je isključeno'**
  String get studioAccessDisabledSummary;

  /// No description provided for @bookingSettingsSummary.
  ///
  /// In hr, this message translates to:
  /// **'Rok za povrat: {hours} h'**
  String bookingSettingsSummary(int hours);

  /// No description provided for @paymentSettingsSummary.
  ///
  /// In hr, this message translates to:
  /// **'{recipient} · {iban}'**
  String paymentSettingsSummary(String recipient, String iban);

  /// No description provided for @reminderSettingsSummary.
  ///
  /// In hr, this message translates to:
  /// **'Slanje u {time}'**
  String reminderSettingsSummary(String time);

  /// No description provided for @classTypesSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Vrste treninga'**
  String get classTypesSettingsTitle;

  /// No description provided for @classTypesProfileSubtitle.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj i uređuj vrste treninga'**
  String get classTypesProfileSubtitle;

  /// No description provided for @classTypesSettingsSummary.
  ///
  /// In hr, this message translates to:
  /// **'{count} konfiguriranih vrsta'**
  String classTypesSettingsSummary(int count);

  /// No description provided for @measurementParametersSettingsTitle.
  ///
  /// In hr, this message translates to:
  /// **'Parametri antropometrije'**
  String get measurementParametersSettingsTitle;

  /// No description provided for @addClassType.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj vrstu treninga'**
  String get addClassType;

  /// No description provided for @editClassType.
  ///
  /// In hr, this message translates to:
  /// **'Uredi vrstu treninga'**
  String get editClassType;

  /// No description provided for @noClassTypes.
  ///
  /// In hr, this message translates to:
  /// **'Još nema vrsta treninga.'**
  String get noClassTypes;

  /// No description provided for @classTypeDefaults.
  ///
  /// In hr, this message translates to:
  /// **'{duration} min · kapacitet {capacity}'**
  String classTypeDefaults(int duration, int capacity);

  /// No description provided for @classTypeCreated.
  ///
  /// In hr, this message translates to:
  /// **'Vrsta treninga je dodana.'**
  String get classTypeCreated;

  /// No description provided for @classTypeUpdated.
  ///
  /// In hr, this message translates to:
  /// **'Vrsta treninga je ažurirana.'**
  String get classTypeUpdated;

  /// No description provided for @classTypeDeleted.
  ///
  /// In hr, this message translates to:
  /// **'Vrsta treninga je obrisana.'**
  String get classTypeDeleted;

  /// No description provided for @classTypeDeactivated.
  ///
  /// In hr, this message translates to:
  /// **'Vrsta treninga je označena neaktivnom.'**
  String get classTypeDeactivated;

  /// No description provided for @deleteClassTypeTitle.
  ///
  /// In hr, this message translates to:
  /// **'Obrisati vrstu treninga?'**
  String get deleteClassTypeTitle;

  /// No description provided for @deleteClassTypeQuestion.
  ///
  /// In hr, this message translates to:
  /// **'Želiš li obrisati vrstu treninga „{name}“?'**
  String deleteClassTypeQuestion(String name);

  /// No description provided for @classTypeCannotDeleteTitle.
  ///
  /// In hr, this message translates to:
  /// **'Vrstu treninga nije moguće obrisati'**
  String get classTypeCannotDeleteTitle;

  /// No description provided for @addMeasurementParameter.
  ///
  /// In hr, this message translates to:
  /// **'Dodaj parametar'**
  String get addMeasurementParameter;

  /// No description provided for @reorderMeasurementParametersHint.
  ///
  /// In hr, this message translates to:
  /// **'Dugo pritisnite stavku i povucite je za promjenu redoslijeda.'**
  String get reorderMeasurementParametersHint;

  /// No description provided for @classTypeNameLabel.
  ///
  /// In hr, this message translates to:
  /// **'Naziv vrste treninga'**
  String get classTypeNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In hr, this message translates to:
  /// **'Opis'**
  String get descriptionLabel;

  /// No description provided for @defaultCapacityLabel.
  ///
  /// In hr, this message translates to:
  /// **'Zadani kapacitet'**
  String get defaultCapacityLabel;

  /// No description provided for @difficultyLevelLabel.
  ///
  /// In hr, this message translates to:
  /// **'Razina težine'**
  String get difficultyLevelLabel;

  /// No description provided for @difficultyBeginner.
  ///
  /// In hr, this message translates to:
  /// **'Početna'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In hr, this message translates to:
  /// **'Srednja'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In hr, this message translates to:
  /// **'Napredna'**
  String get difficultyAdvanced;

  /// No description provided for @difficultyAllLevels.
  ///
  /// In hr, this message translates to:
  /// **'Sve razine'**
  String get difficultyAllLevels;

  /// No description provided for @statusLabel.
  ///
  /// In hr, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @deleteItem.
  ///
  /// In hr, this message translates to:
  /// **'Ukloni'**
  String get deleteItem;

  /// No description provided for @parameterNameLabel.
  ///
  /// In hr, this message translates to:
  /// **'Naziv parametra'**
  String get parameterNameLabel;

  /// No description provided for @unitLabel.
  ///
  /// In hr, this message translates to:
  /// **'Jedinica'**
  String get unitLabel;

  /// No description provided for @invalidInteger.
  ///
  /// In hr, this message translates to:
  /// **'Unesi cijeli broj.'**
  String get invalidInteger;

  /// No description provided for @discardChangesTitle.
  ///
  /// In hr, this message translates to:
  /// **'Odbaciti promjene?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesMessage.
  ///
  /// In hr, this message translates to:
  /// **'Nespremljene promjene bit će izgubljene.'**
  String get discardChangesMessage;

  /// No description provided for @discardAction.
  ///
  /// In hr, this message translates to:
  /// **'Odbaci'**
  String get discardAction;

  /// No description provided for @configurationSaved.
  ///
  /// In hr, this message translates to:
  /// **'Konfiguracija je spremljena.'**
  String get configurationSaved;

  /// No description provided for @classTypeDeleteConflict.
  ///
  /// In hr, this message translates to:
  /// **'Korištenu vrstu treninga nije moguće ukloniti. Označi je neaktivnom.'**
  String get classTypeDeleteConflict;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hr':
      return AppLocalizationsHr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
