import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/attendance_repository.dart';

class GetAttendancesByMonthUseCase {
  final AttendanceRepository _repository;

  GetAttendancesByMonthUseCase(this._repository);

  Future<AsyncValue<List<Attendance>>> execute({
    required List<String> memberIds,
    required String groupId,
    required DateTime displayedMonth,
  }) async {
    final startDate = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final endDate = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);

    final result = await _repository.fetchAttendancesByMemberIds(
      memberIds: memberIds,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
    );

    // Result<T>를 AsyncValue<T>로 변환
    if (result is Success<List<Attendance>>) {
      return AsyncData(result.data);
    } else if (result is Error) {
      final failure = (result as Error).failure;
      return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }

    // 이 코드에 도달할 일은 없지만, 컴파일러를 위해 추가
    return const AsyncLoading();
  }
}