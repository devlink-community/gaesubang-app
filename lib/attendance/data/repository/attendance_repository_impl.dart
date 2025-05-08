import '../../../core/result/result.dart';
import '../../domain/repository/attendance_repository.dart';
import '../../domain/model/attendance.dart';
import '../data_source/attendance_data_source.dart';
import '../dto/attendance_dto.dart';
import '../mapper/attendance_mapper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Attendance>>> fetchAttendancesByDate({
    required  List<String> memberIds,
    required DateTime date,
  }) async {
    try {
      final rawList = await _dataSource.fetchAttendancesByDate(
        memberIds: memberIds,
        date: date,
      );
      final dtoList = rawList.map((e) => AttendanceDto.fromJson(e)).toList();
      final modelList = dtoList.toModelList();
      return Result.success(modelList);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
