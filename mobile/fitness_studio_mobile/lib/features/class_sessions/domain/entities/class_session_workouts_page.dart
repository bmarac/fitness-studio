import 'class_session.dart';

class ClassSessionWorkoutsPage {
  const ClassSessionWorkoutsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasNextPage,
  });

  final List<ClassSession> items;
  final int page;
  final int pageSize;
  final bool hasNextPage;
}
