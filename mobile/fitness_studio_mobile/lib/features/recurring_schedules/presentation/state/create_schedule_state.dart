import '../../../../core/error/failure.dart';
import '../../domain/entities/schedule_form_data.dart';

sealed class CreateScheduleState {
  const CreateScheduleState();
}

class CreateScheduleLoading extends CreateScheduleState {
  const CreateScheduleLoading();
}

class CreateScheduleReady extends CreateScheduleState {
  const CreateScheduleReady({
    required this.formData,
    this.isSubmitting = false,
    this.failure,
  });

  final ScheduleFormData formData;
  final bool isSubmitting;
  final Failure? failure;

  CreateScheduleReady copyWith({
    bool? isSubmitting,
    Failure? failure,
    bool clearError = false,
  }) {
    return CreateScheduleReady(
      formData: formData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearError ? null : failure ?? this.failure,
    );
  }
}

class CreateScheduleLoadError extends CreateScheduleState {
  const CreateScheduleLoadError(this.failure);

  final Failure failure;
}

class CreateScheduleSuccess extends CreateScheduleState {
  const CreateScheduleSuccess();
}
