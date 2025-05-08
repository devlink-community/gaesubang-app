import '../../../core/result/result.dart';
import '../model/attendance.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<Attendance>>> fetchAttendancesByGroup({
    required String groupId,
    // required DateTime date,
  });
}
