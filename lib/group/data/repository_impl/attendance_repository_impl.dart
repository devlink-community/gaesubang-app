import 'package:devlink_mobile_app/group/domain/model/attendance.dart';

import '../../../core/result/result.dart';
import '../../domain/repository/attendance_repository.dart';
import '../data_source/attendance_data_source.dart';
import '../dto/attendance_dto_old.dart';
import '../mapper/attendance_mapper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Attendance>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rawList = await _dataSource.fetchAttendancesByMemberIds(
        memberIds: memberIds,
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      final dtoList = rawList.map((e) => AttendanceDto.fromJson(e)).toList();
      final modelList = dtoList.toModelList();
      return Result.success(modelList);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }

  @override
  Future<Result<void>> recordTimerAttendance({
    required String groupId,
    required String memberId,
    required DateTime date,
    required int timeInMinutes,
  }) async {
    try {
      await _dataSource.recordTimerAttendance(
        groupId: groupId,
        memberId: memberId,
        date: date,
        timeInMinutes: timeInMinutes,
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
