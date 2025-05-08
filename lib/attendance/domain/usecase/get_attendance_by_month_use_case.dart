import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/attendance_repository.dart';

class GetAttendancesByMonthUseCase {
  final AttendanceRepository _repository;

  GetAttendancesByMonthUseCase(this._repository);

  Future<Result<List<Attendance>>> execute({
    required List<String> memberIds,
    required DateTime displayedMonth,
  }) {
    final startDate = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final endDate = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);

    return _repository.fetchAttendancesByMemberIds(
      memberIds: memberIds,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
