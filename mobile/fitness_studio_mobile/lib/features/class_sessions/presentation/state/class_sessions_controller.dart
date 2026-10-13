import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../injection/service_locator.dart';
import '../../domain/usecases/get_class_sessions.dart';
import 'class_sessions_state.dart';

final classSessionsControllerProvider =
    NotifierProvider<ClassSessionsController, ClassSessionsState>(
      ClassSessionsController.new,
    );

class ClassSessionsController extends Notifier<ClassSessionsState> {
  late final GetClassSessions _getClassSessions;
  DateTime? _from;
  DateTime? _to;

  @override
  ClassSessionsState build() {
    _getClassSessions = serviceLocator<GetClassSessions>();
    return const ClassSessionsInitial();
  }

  Future<void> loadClassSessions({DateTime? from, DateTime? to}) async {
    _from = from ?? _from;
    _to = to ?? _to;
    state = const ClassSessionsLoading();

    final result = await _getClassSessions(from: _from, to: _to);

    state = switch (result) {
      Success(value: final classSessions) => ClassSessionsLoaded(classSessions),
      FailureResult(failure: final failure) => ClassSessionsError(failure),
    };
  }
}
