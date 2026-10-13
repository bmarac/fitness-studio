import 'booking.dart';

class MemberBookingsPage {
  const MemberBookingsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
  });

  final List<Booking> items;
  final int page;
  final int pageSize;
  final bool hasNextPage;
}
