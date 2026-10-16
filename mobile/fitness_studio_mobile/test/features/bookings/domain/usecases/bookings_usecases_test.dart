import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/entities/booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/entities/member_bookings_page.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/cancel_booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/cancel_fixed_schedule.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/create_booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/get_bookings.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/get_class_session_bookings.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/get_member_bookings_page.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/usecases/update_booking_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'read use cases forward filters, paging, and session identifiers',
    () async {
      final repository = _FakeBookingsRepository();

      final all = await GetBookings(repository)();
      final session = await GetClassSessionBookings(repository)(21);
      final page = await GetMemberBookingsPage(repository)(
        filter: 'history',
        page: 3,
        pageSize: 15,
      );

      expect((all as Success).value.single.id, 31);
      expect((session as Success).value.single.classSessionId, 21);
      expect((page as Success).value.page, 3);
      expect(repository.classSessionId, 21);
      expect(repository.pageArguments, ('history', 3, 15));
    },
  );

  test(
    'mutation use cases forward exact identifiers, status, and date',
    () async {
      final repository = _FakeBookingsRepository();
      final effectiveFrom = DateTime(2030, 1, 15);

      final created = await CreateBooking(repository)(
        memberId: 11,
        classSessionId: 21,
      );
      await CancelBooking(repository)(31);
      await UpdateBookingStatus(repository)(id: 31, status: 'attended');
      await CancelFixedSchedule(repository)(
        id: 41,
        effectiveFrom: effectiveFrom,
      );

      expect((created as Success).value.id, 31);
      expect(repository.createArguments, (11, 21));
      expect(repository.cancelledBookingId, 31);
      expect(repository.statusArguments, (31, 'attended'));
      expect(repository.fixedScheduleArguments, (41, effectiveFrom));
    },
  );
}

class _FakeBookingsRepository implements BookingsRepository {
  final booking = Booking(
    id: 31,
    memberId: 11,
    memberFirstName: 'Ana',
    memberLastName: 'Horvat',
    classSessionId: 21,
    bookingSource: 'self_service',
    memberFixedScheduleId: null,
    classTypeId: 5,
    classTypeName: 'Pilates',
    trainerId: 7,
    trainerFirstName: 'Filip',
    trainerLastName: 'Šarić',
    classSessionStartsAt: DateTime.utc(2030, 1, 20, 17),
    classSessionEndsAt: DateTime.utc(2030, 1, 20, 18),
    status: 'booked',
    bookedAt: DateTime.utc(2030, 1, 10),
    cancelledAt: null,
    attendedAt: null,
  );

  int? classSessionId;
  (String, int, int)? pageArguments;
  (int, int)? createArguments;
  int? cancelledBookingId;
  (int, String)? statusArguments;
  (int, DateTime)? fixedScheduleArguments;

  @override
  Future<Result<List<Booking>>> getBookings() async => Success([booking]);

  @override
  Future<Result<List<Booking>>> getBookingsByClassSessionId(
    int classSessionId,
  ) async {
    this.classSessionId = classSessionId;
    return Success([booking]);
  }

  @override
  Future<Result<MemberBookingsPage>> getMemberBookingsPage({
    required String filter,
    required int page,
    required int pageSize,
  }) async {
    pageArguments = (filter, page, pageSize);
    return Success(
      MemberBookingsPage(
        items: [booking],
        page: page,
        pageSize: pageSize,
        hasNextPage: false,
      ),
    );
  }

  @override
  Future<Result<Booking>> createBooking({
    required int memberId,
    required int classSessionId,
  }) async {
    createArguments = (memberId, classSessionId);
    return Success(booking);
  }

  @override
  Future<Result<void>> cancelBooking(int id) async {
    cancelledBookingId = id;
    return const Success(null);
  }

  @override
  Future<Result<void>> updateBookingStatus({
    required int id,
    required String status,
  }) async {
    statusArguments = (id, status);
    return const Success(null);
  }

  @override
  Future<Result<void>> cancelFixedSchedule({
    required int id,
    required DateTime effectiveFrom,
  }) async {
    fixedScheduleArguments = (id, effectiveFrom);
    return const Success(null);
  }
}
