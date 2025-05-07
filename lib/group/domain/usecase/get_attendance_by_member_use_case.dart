import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/attendance_repository.dart';


class GetAttendanceByMemberUseCase {
  final AttendanceRepository repository;

  GetAttendanceByMemberUseCase(this.repository);

  Future<Result<List<Attendance>>> execute(String memberId) {
    return repository.getAttendancesByMember(memberId);
  }
}
