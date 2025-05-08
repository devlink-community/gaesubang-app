import '../../../core/result/result.dart';
import '../model/attendance.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<Attendance>>> fetchAttendancesByDate({
    required List<String> memberIds,
    required DateTime date,
  });
}
