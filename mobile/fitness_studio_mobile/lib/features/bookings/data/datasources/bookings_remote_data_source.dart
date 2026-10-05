import '../../../../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingsRemoteDataSource {
  const BookingsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<void> cancelBooking(int id) async {
    await _apiClient.delete<void>('/api/bookings/$id');
  }

  Future<void> cancelFixedSchedule({
    required int id,
    required DateTime effectiveFrom,
  }) async {
    await _apiClient.patch<void>(
      '/api/member-fixed-schedules/$id/cancel',
      data: {'effectiveFrom': _formatDate(effectiveFrom)},
    );
  }

  Future<void> updateBookingStatus({
    required int id,
    required String status,
  }) async {
    await _apiClient.patch<void>(
      '/api/bookings/$id/status',
      data: {'status': status},
    );
  }

  Future<List<BookingModel>> getBookingsByClassSessionId(
    int classSessionId,
  ) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/bookings',
      queryParameters: {'classSessionId': classSessionId},
    );

    return (response.data ?? [])
        .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> createBooking({
    required int memberId,
    required int classSessionId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/bookings',
      data: {'memberId': memberId, 'classSessionId': classSessionId},
    );
    final data = response.data;

    if (data == null) {
      throw const FormatException('Booking response is empty.');
    }

    return BookingModel.fromJson(data);
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
