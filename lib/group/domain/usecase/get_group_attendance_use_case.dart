import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../model/member_attendance.dart';
import '../repository/attendance_repository.dart';
import '../../../core/result/result.dart';

class GetGroupAttendanceUseCase {
  final AttendanceRepository _repository;

  GetGroupAttendanceUseCase(this._repository);

  Future<AsyncValue<List<MemberAttendance>>> execute(String groupId, DateTime date) async {
    final result = await _repository.getAttendanceByDate(groupId, date);

    switch (result) {
      case Success(data: final data):
        return AsyncData(data);
      case Error(failure: final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
