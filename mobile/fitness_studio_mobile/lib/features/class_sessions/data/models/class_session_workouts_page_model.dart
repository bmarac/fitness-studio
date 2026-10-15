import '../../domain/entities/class_session_workouts_page.dart';
import 'class_session_model.dart';

class ClassSessionWorkoutsPageModel extends ClassSessionWorkoutsPage {
  const ClassSessionWorkoutsPageModel({
    required super.items,
    required super.page,
    required super.pageSize,
    required super.hasNextPage,
  });

  factory ClassSessionWorkoutsPageModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>;
    return ClassSessionWorkoutsPageModel(
      items: rawItems
          .map(
            (item) => ClassSessionModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      hasNextPage: json['hasNextPage'] as bool,
    );
  }
}
