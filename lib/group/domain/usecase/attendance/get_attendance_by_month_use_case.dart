// lib/group/domain/usecase/attendance/get_attendance_by_month_use_case.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/result/result.dart';
import '../../model/attendance.dart';
import '../../repository/group_repository.dart';

class GetAttendancesByMonthUseCase {
  final GroupRepository _repository;

  GetAttendancesByMonthUseCase({required GroupRepository repository})
    : _repository = repository;

  Future<AsyncValue<List<Attendance>>> execute({
    required String groupId,
    required int year,
    required int month,
  }) async {
    try {
      // 출석 데이터 조회 (이미 Repository에서 캐시된 멤버 정보와 결합됨)
      final result = await _repository.getAttendancesByMonth(
        groupId,
        year,
        month,
      );

      // Result<T>를 AsyncValue<T>로 변환
      return switch (result) {
        Success(:final data) => AsyncData(data),
        Error(:final failure) => AsyncError(
          failure,
          failure.stackTrace ?? StackTrace.current,
        ),
      };
    } catch (e, st) {
      // 예외 처리
      return AsyncError(e, st);
    }
  }
}
