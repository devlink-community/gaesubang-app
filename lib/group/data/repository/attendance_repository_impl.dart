import '../../../core/result/result.dart';
import '../../domain/repository/attendance_repository.dart';
import '../../domain/model/attendance.dart';
import '../data_source/attendance_data_source.dart';
import '../dto/attendance_dto.dart';
import '../mapper/attendance_mapper.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource dataSource;

  AttendanceRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Attendance>>> fetchAttendancesByGroup({
    required String groupId,
    // required DateTime date,
  }) async {
    try {
      final rawList = await dataSource.fetchAttendancesByGroup(
        groupId: groupId,
        // date: date,
      );
      final dtoList = rawList.map((e) => AttendanceDto.fromJson(e)).toList();
      final modelList = dtoList.toModelList();
      return Result.success(modelList);
    } catch (e, st) {
      return Result.error(mapExceptionToFailure(e, st));
    }
  }
}
