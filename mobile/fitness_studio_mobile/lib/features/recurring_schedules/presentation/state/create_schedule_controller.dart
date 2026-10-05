import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/entities/recurring_schedule_draft.dart';
import '../../domain/repositories/recurring_schedules_repository.dart';
import 'create_schedule_state.dart';

final createScheduleControllerProvider =
    NotifierProvider.autoDispose<CreateScheduleController, CreateScheduleState>(
      CreateScheduleController.new,
    );

class CreateScheduleController extends Notifier<CreateScheduleState> {
  late final RecurringSchedulesRepository _repository;

  @override
  CreateScheduleState build() {
    _repository = serviceLocator<RecurringSchedulesRepository>();
    Future.microtask(loadFormData);
    return const CreateScheduleLoading();
  }

  Future<void> loadFormData() async {
    state = const CreateScheduleLoading();
    final result = await _repository.getFormData();

    state = switch (result) {
      Success(value: final formData) => CreateScheduleReady(formData: formData),
      FailureResult(failure: final failure) => CreateScheduleLoadError(
        failure.message,
      ),
    };
  }

  Future<void> submit(RecurringScheduleDraft draft) async {
    final currentState = state;
    if (currentState is! CreateScheduleReady || currentState.isSubmitting) {
      return;
    }

    state = currentState.copyWith(isSubmitting: true, clearError: true);
    final result = await _repository.createSchedule(draft);

    state = switch (result) {
      Success() => const CreateScheduleSuccess(),
      FailureResult(failure: final failure) => currentState.copyWith(
        isSubmitting: false,
        errorMessage: failure.message,
      ),
    };
  }
}
