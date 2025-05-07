import '../../../core/result/result.dart';
import '../../domain/model/member_attendance.dart';
import '../../data/data_source/attendance_data_source.dart';
import '../../data/dto/timer_dto.dart';
import '../../data/mapper/member_attendance_mapper.dart';
import '../../domain/repository/attendance_repository.dart'; // 여기 확장 정의

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<MemberAttendance>>> getAttendanceByDate(String groupId, DateTime date) async {
    try {
      final List<Map<String, dynamic>> rawList =
      await _dataSource.fetchTimersByGroupAndDate(groupId, date);

      final List<TimerDto> dtoList = rawList.map((e) => TimerDto.fromJson(e)).toList();
      final List<MemberAttendance> models = dtoList.toAttendanceList();

      return Result.success(models);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
