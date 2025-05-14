import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../repository/attendance_repository.dart';

class RecordTimerAttendanceUseCase {
  final AttendanceRepository _repository;

  RecordTimerAttendanceUseCase(this._repository);

  Future<AsyncValue<void>> execute({
    required String groupId,
    required String memberId,
    required DateTime date,
    required int timeInMinutes,
  }) async {
    final result = await _repository.recordTimerAttendance(
      groupId: groupId,
      memberId: memberId,
      date: date,
      timeInMinutes: timeInMinutes,
    );

    return switch (result) {
      Success() => const AsyncData(null),
      Error(:final failure) => AsyncError(failure, failure.stackTrace ?? StackTrace.current)
    };
  }
}