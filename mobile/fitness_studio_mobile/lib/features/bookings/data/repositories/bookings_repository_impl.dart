import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/member_bookings_page.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_remote_data_source.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  const BookingsRepositoryImpl(this._remoteDataSource);

  final BookingsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Booking>>> getBookings() async {
    try {
      return Success(await _remoteDataSource.getBookings());
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readBookings));
    }
  }

  @override
  Future<Result<MemberBookingsPage>> getMemberBookingsPage({
    required String filter,
    required int page,
    required int pageSize,
  }) async {
    try {
      return Success(
        await _remoteDataSource.getMemberBookingsPage(
          filter: filter,
          page: page,
          pageSize: pageSize,
        ),
      );
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readBookings));
    }
  }

  @override
  Future<Result<void>> cancelBooking(int id) async {
    try {
      await _remoteDataSource.cancelBooking(id);
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }

  @override
  Future<Result<void>> cancelFixedSchedule({
    required int id,
    required DateTime effectiveFrom,
  }) async {
    try {
      await _remoteDataSource.cancelFixedSchedule(
        id: id,
        effectiveFrom: effectiveFrom,
      );
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }

  @override
  Future<Result<void>> updateBookingStatus({
    required int id,
    required String status,
  }) async {
    try {
      await _remoteDataSource.updateBookingStatus(id: id, status: status);
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    }
  }

  @override
  Future<Result<List<Booking>>> getBookingsByClassSessionId(
    int classSessionId,
  ) async {
    try {
      final bookings = await _remoteDataSource.getBookingsByClassSessionId(
        classSessionId,
      );
      return Success(bookings);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }

  @override
  Future<Result<Booking>> createBooking({
    required int memberId,
    required int classSessionId,
  }) async {
    try {
      final booking = await _remoteDataSource.createBooking(
        memberId: memberId,
        classSessionId: classSessionId,
      );

      return Success(booking);
    } on ApiException catch (error) {
      return FailureResult(error.toFailure());
    } on FormatException {
      return const FailureResult(Failure(FailureKind.readApi));
    }
  }
}
