import '../../../../core/error/result.dart';
import '../entities/member_progress.dart';
import '../entities/progress_management.dart';

abstract class ProgressRepository {
  Future<Result<MemberProgress>> getMemberProgress(int memberId);
  Future<Result<List<ProgressMember>>> getMembers();
  Future<Result<List<MeasurementParameter>>> getMeasurementParameters();
  Future<Result<void>> createMeasurement(
    int memberId,
    NewMeasurement measurement,
  );
}
