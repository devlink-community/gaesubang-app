import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/user_streak.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetStreakDaysUseCase {
  final GroupRepository _groupRepository;

  GetStreakDaysUseCase({required GroupRepository groupRepository})
    : _groupRepository = groupRepository;

  /// 현재 로그인한 사용자가 가입한 모든 그룹 중 최대 연속 출석일 조회
  ///
  /// Returns: AsyncValue<UserStreak> - 사용자의 최대 연속 출석일 정보
  Future<AsyncValue<UserStreak>> execute() async {
    final result = await _groupRepository.getUserMaxStreakDays();

    switch (result) {
      case Success(:final data):
        return AsyncData(data);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
