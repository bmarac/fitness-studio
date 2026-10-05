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
    this.errorMessage,
  });

  final ScheduleFormData formData;
  final bool isSubmitting;
  final String? errorMessage;

  CreateScheduleReady copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateScheduleReady(
      formData: formData,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CreateScheduleLoadError extends CreateScheduleState {
  const CreateScheduleLoadError(this.message);

  final String message;
}

class CreateScheduleSuccess extends CreateScheduleState {
  const CreateScheduleSuccess();
}
