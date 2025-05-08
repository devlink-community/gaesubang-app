import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/attendance_repository.dart';

class GetAttendanceByGroupUseCase {
  final AttendanceRepository repository;

  GetAttendanceByGroupUseCase(this.repository);

  Future<Result<List<Attendance>>> execute({
    required String groupId,
    // required DateTime date,
  }) {
    return repository.fetchAttendancesByGroup(groupId: groupId,
        // date: date
    );
  }
}
