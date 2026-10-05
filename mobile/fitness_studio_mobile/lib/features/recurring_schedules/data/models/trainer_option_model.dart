import '../../domain/entities/trainer_option.dart';

class TrainerOptionModel extends TrainerOption {
  const TrainerOptionModel({
    required super.id,
    required super.firstName,
    required super.lastName,
  });

  factory TrainerOptionModel.fromJson(Map<String, dynamic> json) {
    return TrainerOptionModel(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}
