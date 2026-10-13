import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/entities/booking.dart';
import 'package:fitness_studio_mobile/features/bookings/domain/entities/member_bookings_page.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/state/member_bookings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, appends, and de-duplicates member booking pages', () async {
    final first = _booking(1, 'Prvi');
    final second = _booking(2, 'Drugi');
    final calls = <({String filter, int page, int pageSize})>[];
    final container = ProviderContainer(
      overrides: [
        memberBookingsProvider.overrideWith(
          () => MemberBookingsController(
            loader:
                ({required filter, required page, required pageSize}) async {
                  calls.add((filter: filter, page: page, pageSize: pageSize));
                  return Success(
                    MemberBookingsPage(
                      items: page == 1 ? [first] : [first, second],
                      page: page,
                      pageSize: pageSize,
                      hasNextPage: page == 1,
                    ),
                  );
                },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(memberBookingsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.loadNextPage();

    final state = container.read(memberBookingsProvider);
    expect(state.items.map((item) => item.id), [1, 2]);
    expect(state.hasNextPage, isFalse);
    expect(calls.last, (filter: 'active', page: 2, pageSize: 20));
  });

  test('filter change replaces items and keeps the selected filter', () async {
    final active = _booking(1, 'Aktivni');
    final completed = _booking(2, 'Završeni');
    final container = ProviderContainer(
      overrides: [
        memberBookingsProvider.overrideWith(
          () => MemberBookingsController(
            loader:
                ({required filter, required page, required pageSize}) async {
                  return Success(
                    MemberBookingsPage(
                      items: [filter == 'active' ? active : completed],
                      page: page,
                      pageSize: pageSize,
                      hasNextPage: false,
                    ),
                  );
                },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(memberBookingsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.selectFilter(WorkoutFilter.completed);

    final state = container.read(memberBookingsProvider);
    expect(state.filter, WorkoutFilter.completed);
    expect(state.items.single.id, 2);
  });

  test(
    'load-more failure preserves current items and can be retried',
    () async {
      var secondPageAttempts = 0;
      final first = _booking(1, 'Prvi');
      final second = _booking(2, 'Drugi');
      final container = ProviderContainer(
        overrides: [
          memberBookingsProvider.overrideWith(
            () => MemberBookingsController(
              loader:
                  ({required filter, required page, required pageSize}) async {
                    if (page == 2 && secondPageAttempts++ == 0) {
                      return const FailureResult(Failure(FailureKind.network));
                    }
                    return Success(
                      MemberBookingsPage(
                        items: page == 1 ? [first] : [second],
                        page: page,
                        pageSize: pageSize,
                        hasNextPage: page == 1,
                      ),
                    );
                  },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(memberBookingsProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await controller.refresh();
      await controller.loadNextPage();

      expect(container.read(memberBookingsProvider).items, [first]);
      expect(container.read(memberBookingsProvider).loadMoreFailure, isNotNull);

      await controller.retryLoadMore();
      expect(
        container.read(memberBookingsProvider).items.map((item) => item.id),
        [1, 2],
      );
    },
  );
}

Booking _booking(int id, String name) {
  final startsAt = DateTime(2030, 10, 13, 18).add(Duration(days: id));
  return Booking(
    id: id,
    memberId: 10,
    memberFirstName: 'Ana',
    memberLastName: 'Horvat',
    classSessionId: id + 50,
    bookingSource: 'self_service',
    memberFixedScheduleId: null,
    classTypeId: id,
    classTypeName: name,
    trainerId: 8,
    trainerFirstName: 'Filip',
    trainerLastName: 'Šarić',
    classSessionStartsAt: startsAt,
    classSessionEndsAt: startsAt.add(const Duration(hours: 1)),
    status: 'booked',
    bookedAt: startsAt.subtract(const Duration(days: 1)),
    cancelledAt: null,
    attendedAt: null,
  );
}
