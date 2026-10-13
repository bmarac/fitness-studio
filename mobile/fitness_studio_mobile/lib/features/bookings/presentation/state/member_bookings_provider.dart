import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/member_bookings_page.dart';
import '../../domain/usecases/get_member_bookings_page.dart';

enum WorkoutFilter {
  active('active'),
  completed('completed'),
  cancelled('cancelled'),
  all('all');

  const WorkoutFilter(this.apiValue);

  final String apiValue;
}

typedef MemberBookingsLoader =
    Future<Result<MemberBookingsPage>> Function({
      required String filter,
      required int page,
      required int pageSize,
    });

class MemberBookingsState {
  const MemberBookingsState({
    this.filter = WorkoutFilter.active,
    this.items = const [],
    this.nextPage = 1,
    this.hasNextPage = false,
    this.isInitialLoading = true,
    this.isLoadingMore = false,
    this.initialFailure,
    this.loadMoreFailure,
  });

  final WorkoutFilter filter;
  final List<Booking> items;
  final int nextPage;
  final bool hasNextPage;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final Failure? initialFailure;
  final Failure? loadMoreFailure;
}

final memberBookingsProvider =
    NotifierProvider<MemberBookingsController, MemberBookingsState>(
      MemberBookingsController.new,
    );

class MemberBookingsController extends Notifier<MemberBookingsState> {
  MemberBookingsController({MemberBookingsLoader? loader}) : _loader = loader;

  static const _pageSize = 20;

  MemberBookingsLoader? _loader;
  int _requestGeneration = 0;

  @override
  MemberBookingsState build() {
    if (_loader == null) {
      final useCase = serviceLocator<GetMemberBookingsPage>();
      _loader = ({required filter, required page, required pageSize}) =>
          useCase(filter: filter, page: page, pageSize: pageSize);
    }
    Future.microtask(refresh);
    return const MemberBookingsState();
  }

  Future<void> selectFilter(WorkoutFilter filter) async {
    if (state.filter == filter) return;
    await _loadFirstPage(filter);
  }

  Future<void> refresh() => _loadFirstPage(state.filter);

  Future<void> retryLoadMore() => loadNextPage();

  Future<void> loadNextPage() async {
    if (state.isInitialLoading || state.isLoadingMore || !state.hasNextPage) {
      return;
    }

    final generation = _requestGeneration;
    final current = state;
    state = MemberBookingsState(
      filter: current.filter,
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
    );
    if (generation != _requestGeneration) return;

    switch (result) {
      case Success(value: final page):
        final seenIds = current.items.map((item) => item.id).toSet();
        final merged = [
          ...current.items,
          ...page.items.where((item) => seenIds.add(item.id)),
        ];
        state = MemberBookingsState(
          filter: current.filter,
          items: merged,
          nextPage: page.page + 1,
          hasNextPage: page.hasNextPage,
          isInitialLoading: false,
        );
      case FailureResult(failure: final failure):
        state = MemberBookingsState(
          filter: current.filter,
          items: current.items,
          nextPage: current.nextPage,
          hasNextPage: current.hasNextPage,
          isInitialLoading: false,
          loadMoreFailure: failure,
        );
    }
  }

  Future<void> _loadFirstPage(WorkoutFilter filter) async {
    final generation = ++_requestGeneration;
    state = MemberBookingsState(filter: filter);

    final result = await _loader!(
      filter: filter.apiValue,
      page: 1,
      pageSize: _pageSize,
    );
    if (generation != _requestGeneration) return;

    state = switch (result) {
      Success(value: final page) => MemberBookingsState(
        filter: filter,
        items: page.items,
        nextPage: page.page + 1,
        hasNextPage: page.hasNextPage,
        isInitialLoading: false,
      ),
      FailureResult(failure: final failure) => MemberBookingsState(
        filter: filter,
        isInitialLoading: false,
        initialFailure: failure,
      ),
    };
  }
}
