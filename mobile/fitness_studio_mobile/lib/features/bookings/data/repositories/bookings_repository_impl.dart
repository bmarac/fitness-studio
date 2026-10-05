import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_remote_data_source.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  const BookingsRepositoryImpl(this._remoteDataSource);

  final BookingsRemoteDataSource _remoteDataSource;

  @override
  Future<Result<void>> cancelBooking(int id) async {
    try {
      await _remoteDataSource.cancelBooking(id);
      return const Success(null);
    } on ApiException catch (error) {
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
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
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
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
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
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
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
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
      return FailureResult(
        Failure(message: error.message, statusCode: error.statusCode),
      );
    } on FormatException {
      return const FailureResult(
        Failure(message: 'Nije moguce procitati podatke s API-ja.'),
      );
    }
  }
}
