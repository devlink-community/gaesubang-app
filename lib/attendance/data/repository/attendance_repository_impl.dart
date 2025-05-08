import 'package:devlink_mobile_app/attendance/data/mapper/attendance_mapper.dart';

import '../../../core/result/result.dart';
import '../../domain/model/attendance.dart';
import '../../domain/repository/attendance_repository.dart';
import '../data_source/attendance_data_source.dart';
import '../dto/attendance_dto.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Attendance>>> fetchAttendancesByMemberIds({
    required List<String> memberIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final rawList = await _dataSource.fetchAttendancesByMemberIds(
        memberIds: memberIds,
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
}
