enum FailureKind {
  remote,
  restoreSession,
  logout,
  loginResponse,
  saveSession,
  readApi,
  readBookings,
  readTrainers,
  readSchedules,
  readScheduleForm,
  readScheduleResponse,
  readProgress,
  readMembers,
  readMeasurementParameters,
  saveMeasurement,
  notFound,
  network,
}

class Failure {
  const Failure(this.kind, {this.remoteMessage, this.statusCode});

  const Failure.remote(String message, {int? statusCode})
    : this(FailureKind.remote, remoteMessage: message, statusCode: statusCode);

  final FailureKind kind;
  final String? remoteMessage;
  final int? statusCode;

  @override
  String toString() => remoteMessage ?? kind.name;
}
