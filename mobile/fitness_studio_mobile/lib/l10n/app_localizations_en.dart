// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fitness Studio';

  @override
  String get navClassSessions => 'Classes';

  @override
  String get navRecurringSchedules => 'Schedules';

  @override
  String get navMyWorkouts => 'My workouts';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaving => 'Saving...';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRemove => 'Remove';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelPassword => 'Password';

  @override
  String get labelTrainer => 'Trainer';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelDate => 'Date';

  @override
  String get labelTime => 'Time';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelCapacity => 'Capacity';

  @override
  String get labelMember => 'Member';

  @override
  String get labelNotes => 'Notes';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get logoutTitle => 'Log out';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get logoutQuestion => 'Do you want to log out of the app?';

  @override
  String get logoutAction => 'Log out';

  @override
  String get logoutInProgress => 'Logging out...';

  @override
  String get loginSubtitle => 'Sign in to your studio';

  @override
  String get loginAction => 'Sign in';

  @override
  String get loginInProgress => 'Signing in...';

  @override
  String get loginSuccess => 'You have signed in successfully.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get profileMyPlan => 'My plan';

  @override
  String get profileValid => 'Valid';

  @override
  String profileValidFrom(String date) {
    return 'From $date';
  }

  @override
  String profileValidRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get profileUsedThisWeek => 'Used this week';

  @override
  String get profileUsedThisMonth => 'Used this month';

  @override
  String get profileUsedInMembership => 'Used in membership';

  @override
  String get profileUsedInBillingCycle => 'Used in billing period';

  @override
  String get profileMembersProgress => 'Member anthropometry';

  @override
  String get profileMembersProgressSubtitle => 'View and enter measurements';

  @override
  String get profileMyPayments => 'My membership';

  @override
  String get profileAdminPayments => 'Membership billing';

  @override
  String get profileMyPaymentsSubtitle => 'Payment details and history';

  @override
  String get profileAdminPaymentsSubtitle => 'Review and confirm payments';

  @override
  String get profilePaymentSettings => 'Payment settings';

  @override
  String get profilePaymentSettingsSubtitle =>
      'Recipient, IBAN and payment details';

  @override
  String get profileAnthropometry => 'Anthropometry';

  @override
  String get profileAnthropometrySubtitle => 'Body measurements';

  @override
  String get profileFixedSchedules => 'Fixed classes';

  @override
  String get profileAboutMe => 'About me';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleTrainer => 'Trainer';

  @override
  String get roleMember => 'Member';

  @override
  String get statusActive => 'Active';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusCompleted => 'Completed';

  @override
  String unknownDay(int day) {
    return 'Day $day';
  }

  @override
  String get classSessionsTitle => 'Classes';

  @override
  String get schedulesTooltip => 'Manage schedules';

  @override
  String get noClassSessionsTitle => 'No classes';

  @override
  String get noClassSessionsMessage =>
      'There are currently no scheduled group classes.';

  @override
  String spotsAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots',
      one: '1 spot',
    );
    return '$_temp0';
  }

  @override
  String get classFull => 'Full';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '1 class',
      zero: 'no classes',
    );
    return '$_temp0';
  }

  @override
  String daySessionsSemantics(String day, String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count classes',
      one: '1 class',
      zero: 'no classes',
    );
    return '$day, $date, $_temp0';
  }

  @override
  String get classSessionDetailsTitle => 'Class details';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get labelBookingAvailability => 'Booking';

  @override
  String get bookingAvailable => 'Available';

  @override
  String get bookingUnavailable => 'Unavailable';

  @override
  String get occupancyTitle => 'Occupancy';

  @override
  String reservedCapacity(int booked, int capacity) {
    return '$booked/$capacity booked';
  }

  @override
  String freeSpots(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spots available',
      one: '1 spot available',
    );
    return '$_temp0';
  }

  @override
  String get classIsFull => 'The class is full';

  @override
  String get bookAction => 'Book';

  @override
  String get bookingInProgress => 'Booking...';

  @override
  String get bookingSaved => 'Booking saved.';

  @override
  String get cancelSessionTitle => 'Cancel class';

  @override
  String get cancelSessionAction => 'Cancel class';

  @override
  String get cancelOnlyThisSession => 'Cancel this class';

  @override
  String get cancelOnlyThisSessionQuestion =>
      'Do you want to cancel only this class? Future classes in the schedule will remain active.';

  @override
  String get cancellingSession => 'Cancelling...';

  @override
  String get sessionCancelled => 'The class has been cancelled.';

  @override
  String get loggedUserNotMember =>
      'The signed-in user is not linked to a member.';

  @override
  String get pauseSchedule => 'Pause schedule';

  @override
  String get resumeSchedule => 'Resume schedule';

  @override
  String get finishSchedule => 'End schedule';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Resume';

  @override
  String get finishAction => 'End';

  @override
  String get pauseScheduleMessage =>
      'This and all future classes in the schedule will be cancelled from the selected date. The schedule can be resumed later.';

  @override
  String get resumeScheduleMessage =>
      'Classes and bookings for active fixed members will be recreated from the selected date.';

  @override
  String get finishScheduleMessage =>
      'The schedule and its fixed assignments will end permanently from the selected date. This action cannot be undone.';

  @override
  String get schedulePaused => 'The schedule has been paused.';

  @override
  String get scheduleResumed => 'The schedule has been resumed.';

  @override
  String get scheduleEnded => 'The schedule has ended.';

  @override
  String get attendeesTitle => 'Attendees';

  @override
  String attendeesCapacity(int count, int capacity) {
    return 'Attendees ($count/$capacity)';
  }

  @override
  String get loadingAttendees => 'Loading attendees...';

  @override
  String get attendeesLoadError => 'Attendees are currently unavailable.';

  @override
  String get noAttendees => 'There are no registered attendees.';

  @override
  String get attendedTooltip => 'Attended';

  @override
  String get noShowTooltip => 'Did not attend';

  @override
  String get memberActionsTooltip => 'Member actions';

  @override
  String get removeFromSession => 'Remove from this class';

  @override
  String get removeFromFixedGroup => 'Remove from fixed group';

  @override
  String get removeFromSessionShort => 'Remove from class';

  @override
  String get removeFixedGroupWarning =>
      'The member will be removed from this and all future classes in this fixed group.';

  @override
  String get removeSessionWarning =>
      'The member will be removed from this class only.';

  @override
  String get removedFromFixedGroup =>
      'The member was removed from the fixed group.';

  @override
  String get removedFromSession => 'The member was removed from the class.';

  @override
  String get myWorkoutsTitle => 'My workouts';

  @override
  String get filterWorkouts => 'Filter workouts';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterCancelled => 'Cancelled';

  @override
  String get filterAll => 'All';

  @override
  String get allTrainers => 'All trainers';

  @override
  String get noReservedWorkouts => 'You have no booked workouts.';

  @override
  String get noSessions => 'No classes.';

  @override
  String cancelBookingDetails(String className, String date, String time) {
    return '$className\n$date at $time';
  }

  @override
  String get bookingStatusAttended => 'Attended';

  @override
  String get bookingStatusNoShow => 'No-show';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusLateCancelled => 'Late cancellation';

  @override
  String get bookingStatusWaitlisted => 'Waitlisted';

  @override
  String get bookingStatusBooked => 'Booked';

  @override
  String get bookingSettingsTitle => 'Bookings';

  @override
  String get cancellationCutoffHoursLabel => 'Session return cutoff (hours)';

  @override
  String get cancellationCutoffHoursDescription =>
      'A value from 0 to 168 hours before the session starts.';

  @override
  String get cancellationCutoffHoursValidation =>
      'Enter a whole number from 0 to 168.';

  @override
  String get activeWorkouts => 'Active workouts';

  @override
  String get completedWorkouts => 'Completed workouts';

  @override
  String get cancelledWorkouts => 'Cancelled workouts';

  @override
  String get allWorkouts => 'All workouts';

  @override
  String attendeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attendees',
      one: '1 attendee',
    );
    return '$_temp0';
  }

  @override
  String get sessionStatusCancelled => 'Cancelled';

  @override
  String get sessionStatusCompleted => 'Completed';

  @override
  String get sessionStatusScheduled => 'Scheduled';

  @override
  String get progressTitle => 'Anthropometry';

  @override
  String get measurementAction => 'Measurement';

  @override
  String get noMemberProfileTitle => 'No member profile';

  @override
  String get noMemberProfileMessage =>
      'Anthropometric measurements are available to members.';

  @override
  String get noMeasurementsTitle => 'No measurements';

  @override
  String get noMeasurementsMessage =>
      'No anthropometric measurements have been recorded yet.';

  @override
  String get parameterLabel => 'Parameter';

  @override
  String get currentValue => 'Current';

  @override
  String get chartNeedsTwoMeasurements =>
      'At least two measurements are needed for a chart.';

  @override
  String get progressTrend => 'Trend';

  @override
  String get progressHistory => 'History';

  @override
  String get membersProgressTitle => 'Member anthropometry';

  @override
  String get searchMembers => 'Search members';

  @override
  String get noMembersFound => 'No members found.';

  @override
  String get newMeasurementTitle => 'New measurement';

  @override
  String get enterOneMeasuredParameter =>
      'Enter at least one measured parameter.';

  @override
  String get saveMeasurement => 'Save measurement';

  @override
  String get invalidNumber => 'Enter a valid number.';

  @override
  String minimumValue(String value) {
    return 'The minimum value is $value.';
  }

  @override
  String maximumValue(String value) {
    return 'The maximum value is $value.';
  }

  @override
  String get enterOneValue => 'Enter at least one value.';

  @override
  String get newScheduleTitle => 'New schedule';

  @override
  String get recurringScheduleDescription =>
      'The class will repeat every week from the selected date.';

  @override
  String get missingClassTypesOrTrainers =>
      'Class types or trainers are missing.';

  @override
  String get classTypeLabel => 'Class type';

  @override
  String get dayLabel => 'Day';

  @override
  String get startTimeLabel => 'Start time';

  @override
  String get durationMinutesLabel => 'Duration (min)';

  @override
  String get positiveNumberRequired => 'Enter a number greater than 0.';

  @override
  String get validFromLabel => 'Valid from';

  @override
  String get saveSchedule => 'Save schedule';

  @override
  String get scheduleCreated => 'Schedule saved.';

  @override
  String get schedulesTitle => 'Schedules';

  @override
  String get filterSchedules => 'Filter schedules';

  @override
  String scheduleFixedOccupancy(int active, int capacity) {
    return '$active/$capacity members';
  }

  @override
  String get noSchedules => 'No schedules have been created.';

  @override
  String get activeSchedules => 'Active';

  @override
  String get pausedSchedules => 'Paused';

  @override
  String get completedSchedules => 'Completed';

  @override
  String get manageSchedule => 'Manage schedule';

  @override
  String effectiveFromDate(String date) {
    return 'from $date';
  }

  @override
  String get paymentSettingsTitle => 'Payment settings';

  @override
  String get recipientLabel => 'Recipient';

  @override
  String get paymentModelLabel => 'Model';

  @override
  String get paymentReferenceLabel => 'Reference number';

  @override
  String get paymentDescriptionLabel => 'Payment description';

  @override
  String get memberReminderDaysLabel =>
      'Member reminders (days after due date)';

  @override
  String get adminReminderDaysLabel => 'Admin reminders';

  @override
  String get sendTimeLabel => 'Send time (HH:mm)';

  @override
  String get requiredField => 'This field is required.';

  @override
  String get settingsSaved => 'Settings saved.';

  @override
  String get noPaymentsInCategory => 'There are no payments in this category.';

  @override
  String get paymentFilterPending => 'Due';

  @override
  String get paymentFilterReported => 'Awaiting confirmation';

  @override
  String get paymentFilterOverdue => 'Overdue';

  @override
  String get paymentFilterPaid => 'Paid';

  @override
  String get paymentFilterAll => 'All';

  @override
  String get paymentRecipient => 'Recipient';

  @override
  String get paymentModelAndReference => 'Model and reference';

  @override
  String get paymentDescription => 'Description';

  @override
  String paymentDueSummary(
    String plan,
    String period,
    String amount,
    String status,
    String dueDate,
  ) {
    return '$plan · $period\n$amount · $status · due $dueDate';
  }

  @override
  String get paymentStatusUnpaid => 'Unpaid';

  @override
  String get paymentCode => 'Payment code';

  @override
  String get paymentReported => 'I have paid';

  @override
  String get rejectPaymentReport => 'Reject report';

  @override
  String get reopenPayment => 'Reopen';

  @override
  String get endMembership => 'End membership';

  @override
  String endMembershipSummary(String date, String amount) {
    return 'First day I will no longer train: $date\nEstimated final amount: $amount';
  }

  @override
  String get markPaid => 'Mark as paid';

  @override
  String get changeSaved => 'Change saved.';

  @override
  String get hub3PaymentCode => 'HUB3 payment code';

  @override
  String get billingNotEnabled => 'Billing not enabled';

  @override
  String get allMembershipsBillingEnabled =>
      'All active memberships have billing enabled.';

  @override
  String get enableBilling => 'Enable billing';

  @override
  String get activeBilling => 'Active billing';

  @override
  String get noActiveBilling => 'There are no memberships with active billing.';

  @override
  String membershipStarted(String date) {
    return 'Membership started: $date';
  }

  @override
  String get billingValidFrom => 'Billing starts on';

  @override
  String get retroactiveBilling => 'Retroactive billing';

  @override
  String billingStartsSummary(String plan, String start, String next) {
    return '$plan\nBilling starts: $start\nNext charge: $next';
  }

  @override
  String retroactiveBillingWarning(String date) {
    return 'You selected $date. All monthly charges from that date through the current cycle will be created immediately.';
  }

  @override
  String get billingEnabled => 'Billing enabled.';

  @override
  String billingEnabledWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges were created.',
      one: '1 charge was created.',
    );
    return 'Billing enabled. $_temp0';
  }

  @override
  String get noNextBilling => 'none';

  @override
  String get failureRestoreSession => 'The saved session could not be loaded.';

  @override
  String get failureLogout => 'You cannot be logged out right now. Try again.';

  @override
  String get failureLoginResponse => 'The sign-in response could not be read.';

  @override
  String get failureSaveSession =>
      'The sign-in session could not be stored securely.';

  @override
  String get failureReadApi => 'The API response could not be read.';

  @override
  String get failureReadBookings => 'Bookings could not be read.';

  @override
  String get failureReadTrainers => 'Trainers could not be read.';

  @override
  String get failureReadSchedules => 'Schedules could not be read.';

  @override
  String get failureReadScheduleForm => 'The new class data could not be read.';

  @override
  String get failureReadScheduleResponse =>
      'The new class response could not be read.';

  @override
  String get failureReadProgress =>
      'Anthropometric measurements could not be read.';

  @override
  String get failureReadMembers => 'Members could not be loaded.';

  @override
  String get failureReadMeasurementParameters =>
      'Measurement parameters could not be loaded.';

  @override
  String get failureSaveMeasurement => 'The measurement could not be saved.';

  @override
  String get failureBookingAlreadyExists =>
      'You are already booked for this class.';

  @override
  String get failureMembershipRequired =>
      'You do not have a membership that covers this class date.';

  @override
  String get failureMembershipLimitReached =>
      'You have used all classes available in your membership for this period.';

  @override
  String get failureNotFound => 'The requested data was not found.';

  @override
  String get failureNetwork => 'The network request failed.';

  @override
  String get labelStudioCode => 'Studio code';

  @override
  String get studioCodeRequired => 'Enter the studio code.';

  @override
  String get trainersTitle => 'Trainers';

  @override
  String get trainerManagementSubtitle => 'View and pre-register trainers';

  @override
  String get membershipPlansTitle => 'Pricing';

  @override
  String get membershipPlansSubtitle => 'Manage pricing';

  @override
  String get memberPackagesTitle => 'Members and plans';

  @override
  String get memberPackagesSubtitle => 'Assign or change a member’s plan';

  @override
  String get memberPackagesFilterAll => 'All members';

  @override
  String memberPackagesFilterMissing(int count) {
    return 'Without a plan ($count)';
  }

  @override
  String get memberPackageMissing => 'No active plan';

  @override
  String memberPackageFrom(String start) {
    return 'Valid from $start';
  }

  @override
  String memberPackagePeriod(String start, String end) {
    return '$start – $end';
  }

  @override
  String get memberPackageInactiveMemberHint =>
      'Plans cannot be changed for an inactive member.';

  @override
  String get assignMemberPackage => 'Assign plan';

  @override
  String get changeMemberPackage => 'Change plan';

  @override
  String assignPackageTo(String memberName) {
    return 'Assign plan: $memberName';
  }

  @override
  String changePackageFor(String memberName) {
    return 'Change plan: $memberName';
  }

  @override
  String get memberPackageStartsOn => 'Membership start';

  @override
  String get memberPackageEndsOn => 'Membership end';

  @override
  String get memberPackageNoEndDate => 'No end date';

  @override
  String get memberPackageClearEnd => 'Clear end date';

  @override
  String get memberPackagePlanRequired => 'Select a plan.';

  @override
  String get memberPackageEndAfterStart =>
      'The end date must be after the start date.';

  @override
  String get memberPackageOverlap =>
      'The member already has a plan that overlaps the selected period.';

  @override
  String get noActiveMembershipPlans =>
      'There are no active plans available for assignment.';

  @override
  String memberPackageSaved(String memberName) {
    return 'The plan for $memberName was saved.';
  }

  @override
  String get addMembershipPlan => 'Add plan';

  @override
  String get editMembershipPlan => 'Edit plan';

  @override
  String get noMembershipPlans => 'There are no plans yet.';

  @override
  String get membershipPlanName => 'Plan name';

  @override
  String get membershipPlanDescription => 'Description';

  @override
  String get membershipPlanPrice => 'Monthly price';

  @override
  String get membershipPlanLimitEnabled => 'Limit the number of classes';

  @override
  String get membershipPlanSessionLimit => 'Number of classes';

  @override
  String get membershipPlanLimitPeriod => 'Limit period';

  @override
  String get membershipPlanPeriodWeek => 'Week';

  @override
  String get membershipPlanPeriodMonth => 'Month';

  @override
  String get membershipPlanPeriodMembership => 'Membership';

  @override
  String get membershipPlanUnlimited => 'Unlimited classes';

  @override
  String membershipPlanMonthlyPrice(String price) {
    return '$price monthly';
  }

  @override
  String membershipPlanLimitSummary(int count, String period) {
    return '$count classes / $period';
  }

  @override
  String get membershipPlanActive => 'Active plan';

  @override
  String get deleteMembershipPlanTitle => 'Delete plan?';

  @override
  String deleteMembershipPlanQuestion(String name) {
    return 'The $name plan will be permanently deleted.';
  }

  @override
  String get membershipPlanCreated => 'The plan was added.';

  @override
  String get membershipPlanUpdated => 'The plan was saved.';

  @override
  String get membershipPlanDeleted => 'The plan was deleted.';

  @override
  String get membershipPlanCannotDeleteTitle => 'The plan cannot be deleted';

  @override
  String get membershipPlanCannotDeleteMessage =>
      'The plan is linked to existing memberships. You can mark it as inactive instead.';

  @override
  String get deactivateMembershipPlan => 'Mark as inactive';

  @override
  String get membershipPlanDeactivated => 'The plan was marked as inactive.';

  @override
  String get membershipPlanDuplicate => 'A plan with this name already exists.';

  @override
  String get invalidMembershipPlanPrice => 'Enter a valid non-negative price.';

  @override
  String get invalidMembershipPlanLimit =>
      'The class limit must be a positive whole number.';

  @override
  String get addTrainer => 'New trainer';

  @override
  String get noTrainersYet => 'There are no trainers yet.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get bioLabel => 'Bio';

  @override
  String get saveAction => 'Save';

  @override
  String get registerTitle => 'Registration';

  @override
  String get registerAction => 'Create account';

  @override
  String get passwordMinimumLength =>
      'Password must contain at least 10 characters.';

  @override
  String get chooseStudioTitle => 'Choose a studio';

  @override
  String get yourStudios => 'Your studios';

  @override
  String get joinStudioTitle => 'Join a studio';

  @override
  String joinStudioConfirmation(String studioName) {
    return 'Join $studioName';
  }

  @override
  String get checkStudioCode => 'Check code';

  @override
  String get joinStudioAction => 'Join studio';

  @override
  String get firstAndLastNameRequired => 'Enter first name and last name.';

  @override
  String profileCreated(String displayName) {
    return 'Profile $displayName was created.';
  }

  @override
  String get changeOrAddStudio => 'Change or add studio';

  @override
  String get studioSettingsTitle => 'Studio settings';

  @override
  String get studioSettingsSubtitle => 'Access, billing and reminders';

  @override
  String get studioAccessSettingsTitle => 'Studio access';

  @override
  String get reminderSettingsTitle => 'Reminders';

  @override
  String get allowJoinByCode => 'Allow joining by code';

  @override
  String get allowJoinByCodeDescription =>
      'Users can join by entering the studio code.';

  @override
  String get fixedScheduleMembers => 'Members';

  @override
  String get noFixedScheduleMembers =>
      'This schedule currently has no fixed group members.';

  @override
  String get addFixedScheduleMember => 'Add member';

  @override
  String get addFixedScheduleMemberAction => 'Add to fixed group';

  @override
  String get fixedScheduleStartsOn => 'Fixed schedule start';

  @override
  String get noMembersForFixedSchedule =>
      'There are no available active members.';

  @override
  String fixedScheduleMemberAdded(String memberName) {
    return '$memberName was added to the fixed group.';
  }

  @override
  String get fixedScheduleInactiveMember =>
      'Only an active member can be added to a fixed group.';

  @override
  String get fixedScheduleInactiveSchedule =>
      'Members can be added only to an active schedule.';

  @override
  String get fixedScheduleAlreadyAssigned =>
      'The member is already assigned to this fixed schedule.';

  @override
  String get fixedScheduleFull => 'The fixed group has no available places.';

  @override
  String get fixedScheduleChanged =>
      'The schedule changed in the meantime. Please try again.';

  @override
  String get fixedSchedulePackageLimit =>
      'The member’s package does not allow another fixed schedule.';

  @override
  String get moveFixedScheduleMember => 'Move';

  @override
  String selectMoveDestination(String memberName) {
    return 'Choose a new schedule for $memberName';
  }

  @override
  String get cancelMove => 'Cancel move';

  @override
  String get moveDestinationFull => 'Schedule is full';

  @override
  String get moveMemberTitle => 'Move member?';

  @override
  String moveMemberConfirmation(
    String memberName,
    String classType,
    String weekday,
    String time,
  ) {
    return 'Are you sure you want to move $memberName to $classType, $weekday at $time?';
  }

  @override
  String get confirmMove => 'Move';

  @override
  String get fixedScheduleMemberMoved =>
      'The member was moved to the new schedule.';

  @override
  String get scheduleMembersLoadError =>
      'The fixed group members could not be loaded.';

  @override
  String get editSchedule => 'Edit schedule';

  @override
  String get effectiveFromLabel => 'Change takes effect';

  @override
  String get confirmScheduleUpdate => 'Save change';

  @override
  String get scheduleUpdated => 'The schedule change was saved.';

  @override
  String scheduleValidFrom(String date) {
    return 'From $date';
  }

  @override
  String scheduleValidUntil(String date) {
    return 'Until $date';
  }
}
