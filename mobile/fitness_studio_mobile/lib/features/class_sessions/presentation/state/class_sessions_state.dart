import '../../../../core/error/failure.dart';
import '../../domain/entities/class_session.dart';

sealed class ClassSessionsState {
  const ClassSessionsState();
}

class ClassSessionsInitial extends ClassSessionsState {
  const ClassSessionsInitial();
}

class ClassSessionsLoading extends ClassSessionsState {
  const ClassSessionsLoading();
}

class ClassSessionsLoaded extends ClassSessionsState {
  const ClassSessionsLoaded(this.classSessions);

  final List<ClassSession> classSessions;
}

class ClassSessionsError extends ClassSessionsState {
  const ClassSessionsError(this.failure);

  final Failure failure;
}
