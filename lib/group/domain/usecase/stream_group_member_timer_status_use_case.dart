// lib/group/domain/usecase/stream_group_member_timer_status_use_case.dart
import 'package:devlink_mobile_app/core/result/result.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/repository/group_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class StreamGroupMemberTimerStatusUseCase {
  final GroupRepository _repository;

  StreamGroupMemberTimerStatusUseCase({required GroupRepository repository})
    : _repository = repository;

  /// 실시간 그룹 멤버 타이머 상태 스트림
  ///
  /// Repository에서 받은 Result<List<GroupMember>> 스트림을
  /// AsyncValue<List<GroupMember>> 스트림으로 변환하여 반환
  Stream<AsyncValue<List<GroupMember>>> execute(String groupId) {
    return _repository
        .streamGroupMemberTimerStatus(groupId)
        .map(
          (result) => switch (result) {
            Success(:final data) => AsyncData(data),
            Error(:final failure) => AsyncError(
              failure,
              failure.stackTrace ?? StackTrace.current,
            ),
          },
        );
  }
}
