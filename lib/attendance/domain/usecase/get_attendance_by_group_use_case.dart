import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/attendance_repository.dart';

class GetAttendanceByDateUseCase {
  final AttendanceRepository repository;

  GetAttendanceByDateUseCase(this.repository);

  Future<Result<List<Attendance>>> execute({
    required List<String> memberIds,
    required DateTime date,
  }) {
    return repository.fetchAttendancesByDate(memberIds: memberIds, date: date);
  }
}
