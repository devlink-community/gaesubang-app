// lib/group/presentation/group_detail/group_detail_state.dart
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_detail_state.freezed.dart';

@freezed
class GroupDetailState with _$GroupDetailState {
  const GroupDetailState({
    // 타이머 현재 상태 (단순화된 상태)
    this.timerStatus = TimerStatus.stop,

    // 현재 타이머 경과 시간 (초)
    this.elapsedSeconds = 0,

    // 그룹 상세 정보 (AsyncValue로 감싸진 상태)
    this.groupDetailResult = const AsyncValue.loading(),

    // 멤버 목록 (AsyncValue로 감싸진 상태)
    this.groupMembersResult = const AsyncValue.loading(),

    // 에러 메시지 (있는 경우)
    this.errorMessage,
  });

  final TimerStatus timerStatus;
  final int elapsedSeconds;
  final AsyncValue<Group> groupDetailResult;
  final AsyncValue<List<GroupMember>> groupMembersResult;
  final String? errorMessage;
}

// 타이머 상태 열거형 (단순화됨)
enum TimerStatus {
  running, // 실행 중
  paused, // 일시 정지
  stop, // 중지됨
}
