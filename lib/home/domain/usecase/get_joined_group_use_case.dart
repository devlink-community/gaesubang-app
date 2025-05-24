import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GetJoinedGroupUseCase {
  final GroupRepository _groupRepository;

  GetJoinedGroupUseCase({required GroupRepository groupRepository})
    : _groupRepository = groupRepository;

  /// 현재 로그인한 사용자가 가입한 그룹 목록 조회
  ///
  /// Returns: AsyncValue<List<Group>> - 사용자가 가입한 그룹 목록
  /// 현재 로그인한 사용자가 가입한 그룹 목록 조회
  Future<AsyncValue<List<Group>>> execute() async {
    final result = await _groupRepository.getGroupList();

    switch (result) {
      case Success(:final data):
        // 가입된 그룹만 필터링
        final joinedGroups =
            data.where((group) => group.isJoinedByCurrentUser).toList();
        return AsyncData(joinedGroups);
      case Error(:final failure):
        return AsyncError(failure, failure.stackTrace ?? StackTrace.current);
    }
  }
}
