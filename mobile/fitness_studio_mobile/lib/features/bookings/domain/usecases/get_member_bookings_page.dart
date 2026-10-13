import '../../../../core/error/result.dart';
import '../entities/member_bookings_page.dart';
import '../repositories/bookings_repository.dart';

class GetMemberBookingsPage {
  const GetMemberBookingsPage(this._repository);

  final BookingsRepository _repository;

  Future<Result<MemberBookingsPage>> call({
    required String filter,
    required int page,
    int pageSize = 20,
  }) => _repository.getMemberBookingsPage(
    filter: filter,
    page: page,
    pageSize: pageSize,
  );
}
