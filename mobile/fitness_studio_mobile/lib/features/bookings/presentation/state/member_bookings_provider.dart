import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/get_bookings.dart';

final memberBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final result = await serviceLocator<GetBookings>()();

  return switch (result) {
    Success(value: final bookings) =>
      bookings..sort(
        (first, second) =>
            first.classSessionStartsAt.compareTo(second.classSessionStartsAt),
      ),
    FailureResult(failure: final failure) => throw failure,
  };
});
