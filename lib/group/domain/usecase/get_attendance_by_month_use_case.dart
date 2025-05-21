// lib/group/domain/usecase/get_attendance_by_month_use_case.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/result/result.dart';
import '../model/attendance.dart';
import '../repository/group_repository.dart';

class GetAttendancesByMonthUseCase {
  final GroupRepository _repository;

  GetAttendancesByMonthUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Attendance>>> execute({
    required String groupId,
    required int year,
    required int month,
  }) async {
    final result = await _repository.getAttendancesByMonth(
      groupId,
      year,
      month,
    );

    // Result<T>를 AsyncValue<T>로 변환 (switch 표현식 사용)
    return switch (result) {
      Success(:final data) => AsyncData(data),
      Error(:final failure) => AsyncError(
        failure,
        failure.stackTrace ?? StackTrace.current,
      ),
    };
  }
}
