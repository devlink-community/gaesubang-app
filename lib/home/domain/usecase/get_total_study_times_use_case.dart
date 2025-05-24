import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class GetTotalStudyTimesUseCase {
  final GroupRepository _groupRepository;

  GetTotalStudyTimesUseCase({required GroupRepository groupRepository})
    : _groupRepository = groupRepository;

  Future<AsyncValue<int>> execute() async {
    // Repository에 getWeeklyStudyTimeMinutes() 메서드가 추가되어야 함
    final result = await _groupRepository.getWeeklyStudyTimeMinutes();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }

  /// 시간 형태로 포맷된 이번 주 공부 시간 조회
  ///
  /// Returns: AsyncValue<String> - "8시간 30분" 형태의 문자열
  Future<AsyncValue<String>> executeFormatted() async {
    final result = await execute();

    return result.when(
      data: (weeklyMinutes) {
        final hours = weeklyMinutes ~/ 60;
        final minutes = weeklyMinutes % 60;

        if (hours > 0) {
          return AsyncData('$hours시간 $minutes분');
        } else {
          return AsyncData('$minutes분');
        }
      },
      loading: () => const AsyncLoading(),
      error: (error, stackTrace) => AsyncError(error, stackTrace),
    );
  }
}
