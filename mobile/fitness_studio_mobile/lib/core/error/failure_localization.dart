import 'package:flutter/widgets.dart';

import '../l10n/localization.dart';
import '../network/api_exception.dart';
import 'failure.dart';

extension LocalizedFailure on Failure {
  String localized(BuildContext context) {
    final message = remoteMessage;
    if (kind == FailureKind.remote && message != null) {
      if (message ==
          'This member already has an active booking for this class session.') {
        return context.l10n.failureBookingAlreadyExists;
      }
      if (message ==
          'This member does not have a membership that covers the selected class session date.') {
        return context.l10n.failureMembershipRequired;
      }
      if (message ==
          'This member has reached the session limit for the selected membership period.') {
        return context.l10n.failureMembershipLimitReached;
      }
      if (message ==
          'A membership plan with this name already exists in the current studio.') {
        return context.l10n.membershipPlanDuplicate;
      }
      if (message ==
          'Membership plan cannot be deleted because related memberships exist.') {
        return context.l10n.membershipPlanCannotDeleteMessage;
      }
      return message;
    }

    return switch (kind) {
      FailureKind.remote => context.l10n.failureNetwork,
      FailureKind.restoreSession => context.l10n.failureRestoreSession,
      FailureKind.logout => context.l10n.failureLogout,
      FailureKind.loginResponse => context.l10n.failureLoginResponse,
      FailureKind.saveSession => context.l10n.failureSaveSession,
      FailureKind.readApi => context.l10n.failureReadApi,
      FailureKind.readBookings => context.l10n.failureReadBookings,
      FailureKind.readTrainers => context.l10n.failureReadTrainers,
      FailureKind.readSchedules => context.l10n.failureReadSchedules,
      FailureKind.readScheduleForm => context.l10n.failureReadScheduleForm,
      FailureKind.readScheduleResponse =>
        context.l10n.failureReadScheduleResponse,
      FailureKind.readProgress => context.l10n.failureReadProgress,
      FailureKind.readMembers => context.l10n.failureReadMembers,
      FailureKind.readMeasurementParameters =>
        context.l10n.failureReadMeasurementParameters,
      FailureKind.saveMeasurement => context.l10n.failureSaveMeasurement,
      FailureKind.notFound => context.l10n.failureNotFound,
      FailureKind.network => context.l10n.failureNetwork,
    };
  }
}

String localizedError(BuildContext context, Object error) => error is Failure
    ? error.localized(context)
    : error is ApiException
    ? error.message
    : error.toString();
