import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/domain/usecases/get_class_session_bookings.dart';

final classSessionBookingsProvider = FutureProvider.family<List<Booking>, int>((
  ref,
  classSessionId,
) async {
  final result = await serviceLocator<GetClassSessionBookings>()(
    classSessionId,
  );

  return switch (result) {
    Success(value: final bookings) => bookings,
    FailureResult(failure: final failure) => throw failure,
  };
});
