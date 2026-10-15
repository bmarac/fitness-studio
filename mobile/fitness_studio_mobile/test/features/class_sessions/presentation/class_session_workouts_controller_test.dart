import 'package:fitness_studio_mobile/core/error/failure.dart';
import 'package:fitness_studio_mobile/core/error/result.dart';
import 'package:fitness_studio_mobile/features/bookings/presentation/state/member_bookings_provider.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session.dart';
import 'package:fitness_studio_mobile/features/class_sessions/domain/entities/class_session_workouts_page.dart';
import 'package:fitness_studio_mobile/features/class_sessions/presentation/state/my_class_sessions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads, appends, and de-duplicates workout pages', () async {
    final first = _session(1, 7, 'Prvi');
    final second = _session(2, 7, 'Drugi');
    final calls = <({String filter, int page, int pageSize, int? trainerId})>[];
    final container = ProviderContainer(
      overrides: [
        classSessionWorkoutsProvider.overrideWith(
          () => ClassSessionWorkoutsController(
            loader:
                ({
                  required filter,
                  required page,
                  required pageSize,
                  trainerId,
                }) async {
                  calls.add((
                    filter: filter,
                    page: page,
                    pageSize: pageSize,
                    trainerId: trainerId,
                  ));
                  return Success(
                    ClassSessionWorkoutsPage(
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
    final subscription = container.listen(
      classSessionWorkoutsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final controller = container.read(classSessionWorkoutsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.loadNextPage();

    final state = container.read(classSessionWorkoutsProvider);
    expect(state.items.map((item) => item.id), [1, 2]);
    expect(state.hasNextPage, isFalse);
    expect(calls.last, (
      filter: 'active',
      page: 2,
      pageSize: 20,
      trainerId: null,
    ));
  });

  test('filter and trainer changes replace the first page', () async {
    final calls = <({String filter, int? trainerId})>[];
    final container = ProviderContainer(
      overrides: [
        classSessionWorkoutsProvider.overrideWith(
          () => ClassSessionWorkoutsController(
            loader:
                ({
                  required filter,
                  required page,
                  required pageSize,
                  trainerId,
                }) async {
                  calls.add((filter: filter, trainerId: trainerId));
                  return Success(
                    ClassSessionWorkoutsPage(
                      items: [_session(page, trainerId ?? 7, filter)],
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
    final subscription = container.listen(
      classSessionWorkoutsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final controller = container.read(classSessionWorkoutsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.selectFilter(WorkoutFilter.completed);
    await controller.selectTrainer(8);

    final state = container.read(classSessionWorkoutsProvider);
    expect(state.filter, WorkoutFilter.completed);
    expect(state.trainerId, 8);
    expect(state.items.single.trainerId, 8);
    expect(calls.last, (filter: 'completed', trainerId: 8));
  });

  test('load-more failure preserves loaded workouts', () async {
    final first = _session(1, 7, 'Prvi');
    final container = ProviderContainer(
      overrides: [
        classSessionWorkoutsProvider.overrideWith(
          () => ClassSessionWorkoutsController(
            loader:
                ({
                  required filter,
                  required page,
                  required pageSize,
                  trainerId,
                }) async => page == 1
                ? Success(
                    ClassSessionWorkoutsPage(
                      items: [first],
                      page: page,
                      pageSize: pageSize,
                      hasNextPage: true,
                    ),
                  )
                : const FailureResult(Failure(FailureKind.network)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      classSessionWorkoutsProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    final controller = container.read(classSessionWorkoutsProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await controller.refresh();
    await controller.loadNextPage();

    final state = container.read(classSessionWorkoutsProvider);
    expect(state.items, [first]);
    expect(state.loadMoreFailure, isNotNull);
  });
}

ClassSession _session(int id, int trainerId, String name) {
  final startsAt = DateTime(2030, 10, 13, 18).add(Duration(days: id));
  return ClassSession(
    id: id,
    classTypeId: id,
    classTypeName: name,
    trainerId: trainerId,
    trainerFirstName: 'Ana',
    trainerLastName: 'Trener',
    startsAt: startsAt,
    endsAt: startsAt.add(const Duration(hours: 1)),
    capacity: 10,
    bookedCount: 4,
    status: 'scheduled',
    recurringScheduleId: id,
    recurringScheduleStatus: 'active',
  );
}
