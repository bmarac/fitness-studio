import 'class_type_option.dart';
import 'trainer_option.dart';

class ScheduleFormData {
  const ScheduleFormData({required this.classTypes, required this.trainers});

  final List<ClassTypeOption> classTypes;
  final List<TrainerOption> trainers;
}
