import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../injection/service_locator.dart';
import '../../../bookings/presentation/state/member_bookings_provider.dart';
import '../../domain/entities/class_session.dart';
import '../../domain/entities/class_session_workouts_page.dart';
import '../../domain/usecases/get_class_session_workouts_page.dart';
import '../../domain/usecases/get_my_class_sessions.dart';
import '../../domain/usecases/get_class_sessions.dart';
import '../../../recurring_schedules/domain/entities/trainer_option.dart';
import '../../../recurring_schedules/domain/usecases/get_trainers.dart';

final myClassSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  final result = await serviceLocator<GetMyClassSessions>()();

  return switch (result) {
    Success(value: final classSessions) => classSessions,
    FailureResult(failure: final failure) => throw failure,
  };
});

final allClassSessionsProvider = FutureProvider<List<ClassSession>>((
  ref,
) async {
  final result = await serviceLocator<GetClassSessions>()();

  return switch (result) {
    Success(value: final classSessions) => classSessions,
    FailureResult(failure: final failure) => throw failure,
  };
});

final trainerOptionsProvider = FutureProvider<List<TrainerOption>>((ref) async {
  final result = await serviceLocator<GetTrainers>()();

  return switch (result) {
    Success(value: final trainers) =>
      trainers.where((trainer) => trainer.status == 'active').toList(),
    FailureResult(failure: final failure) => throw failure,
  };
});

typedef ClassSessionWorkoutsLoader =
    Future<Result<ClassSessionWorkoutsPage>> Function({
      required String filter,
      required int page,
      required int pageSize,
      int? trainerId,
    });

class ClassSessionWorkoutsState {
  const ClassSessionWorkoutsState({
    this.filter = WorkoutFilter.active,
    this.trainerId,
    this.items = const [],
    this.nextPage = 1,
    this.hasNextPage = false,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.initialFailure,
    this.loadMoreFailure,
  });

  final WorkoutFilter filter;
  final int? trainerId;
  final List<ClassSession> items;
  final int nextPage;
  final bool hasNextPage;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Failure? initialFailure;
  final Failure? loadMoreFailure;
}

final classSessionWorkoutsProvider =
    NotifierProvider.autoDispose<
      ClassSessionWorkoutsController,
      ClassSessionWorkoutsState
    >(ClassSessionWorkoutsController.new);

class ClassSessionWorkoutsController
    extends Notifier<ClassSessionWorkoutsState> {
  ClassSessionWorkoutsController({ClassSessionWorkoutsLoader? loader})
    : _loader = loader;

  static const _pageSize = 20;

  ClassSessionWorkoutsLoader? _loader;
  int _requestGeneration = 0;

  @override
  ClassSessionWorkoutsState build() {
    if (_loader == null) {
      final useCase = serviceLocator<GetClassSessionWorkoutsPage>();
      _loader =
          ({required filter, required page, required pageSize, trainerId}) =>
              useCase(
                filter: filter,
                page: page,
                pageSize: pageSize,
                trainerId: trainerId,
              );
    }
    Future.microtask(refresh);
    return const ClassSessionWorkoutsState();
  }

  Future<void> selectFilter(WorkoutFilter filter) async {
    if (state.filter == filter) return;
    await _loadFirstPage(filter: filter, trainerId: state.trainerId);
  }

  Future<void> selectTrainer(int? trainerId) async {
    if (state.trainerId == trainerId) return;
    await _loadFirstPage(filter: state.filter, trainerId: trainerId);
  }

  Future<void> refresh() =>
      _loadFirstPage(filter: state.filter, trainerId: state.trainerId);

  Future<void> retryLoadMore() => loadNextPage();

  Future<void> loadNextPage() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    final generation = _requestGeneration;
    final current = state;
    state = ClassSessionWorkoutsState(
      filter: current.filter,
      trainerId: current.trainerId,
      items: current.items,
      nextPage: current.nextPage,
      hasNextPage: current.hasNextPage,
      isInitialLoading: false,
      isLoadingMore: true,
    );

    final result = await _loader!(
      filter: current.filter.apiValue,
      page: current.nextPage,
      pageSize: _pageSize,
      trainerId: current.trainerId,
    );
    if (!ref.mounted || generation != _requestGeneration) return;

    switch (result) {
      case Success(value: final page):
        final seenIds = current.items.map((item) => item.id).toSet();
        final merged = [
          ...current.items,
          ...page.items.where((item) => seenIds.add(item.id)),
        ];
        state = ClassSessionWorkoutsState(
          filter: current.filter,
          trainerId: current.trainerId,
          items: merged,
          nextPage: page.page + 1,
          hasNextPage: page.hasNextPage,
          isInitialLoading: false,
        );
      case FailureResult(failure: final failure):
        state = ClassSessionWorkoutsState(
          filter: current.filter,
          trainerId: current.trainerId,
          items: current.items,
          nextPage: current.nextPage,
          hasNextPage: current.hasNextPage,
          isInitialLoading: false,
          loadMoreFailure: failure,
        );
    }
  }

  Future<void> _loadFirstPage({
    required WorkoutFilter filter,
    required int? trainerId,
  }) async {
    final generation = ++_requestGeneration;
    state = ClassSessionWorkoutsState(filter: filter, trainerId: trainerId);

    final result = await _loader!(
      filter: filter.apiValue,
      page: 1,
      pageSize: _pageSize,
      trainerId: trainerId,
    );
    if (!ref.mounted || generation != _requestGeneration) return;

    state = switch (result) {
      Success(value: final page) => ClassSessionWorkoutsState(
        filter: filter,
        trainerId: trainerId,
        items: page.items,
        nextPage: page.page + 1,
        hasNextPage: page.hasNextPage,
        isInitialLoading: false,
      ),
      FailureResult(failure: final failure) => ClassSessionWorkoutsState(
        filter: filter,
        trainerId: trainerId,
        isInitialLoading: false,
        initialFailure: failure,
      ),
    };
  }
}
