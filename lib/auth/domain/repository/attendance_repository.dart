import '../../../core/result/result.dart';
import '../model/member_attendance.dart';

abstract interface class AttendanceRepository {
  Future<Result<List<MemberAttendance>>> getAttendanceByDate(String groupId, DateTime date);
}