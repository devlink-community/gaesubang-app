import '../../../core/result/result.dart';
import '../model/attendance.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<Attendance>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
