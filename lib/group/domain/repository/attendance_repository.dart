import '../model/attendance.dart';
import '../../../core/result/result.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<Attendance>>> getAttendancesByMember(String memberId);
}
