import '../../domain/entities/member_bookings_page.dart';
import 'booking_model.dart';

class MemberBookingsPageModel extends MemberBookingsPage {
  const MemberBookingsPageModel({
    required super.items,
    required super.page,
    required super.pageSize,
    required super.hasNextPage,
  });

  factory MemberBookingsPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];

    return MemberBookingsPageModel(
      items: rawItems
          .map((item) => BookingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}
