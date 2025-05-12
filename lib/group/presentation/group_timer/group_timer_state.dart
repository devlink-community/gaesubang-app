import 'package:devlink_mobile_app/group/domain/model/member_timer.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_session.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_timer_state.freezed.dart';

@freezed
class GroupTimerState with _$GroupTimerState {
  const GroupTimerState({
    // 현재 진행 중인 타이머 세션
    this.activeSession = const AsyncValue.loading(),

    // 타이머 현재 상태 (시작/일시정지/종료)
    this.timerStatus = TimerStatus.initial,

    // 현재 타이머 경과 시간 (초)
    this.elapsedSeconds = 0,

    // 현재 그룹의 전체 타이머 세션 목록
    this.sessions = const AsyncValue.loading(),

    // 선택된 그룹 ID
    this.groupId = '',

    // 그룹명
    this.groupName = '',

    // 현재 참여자 수 / 전체 멤버 수
    this.participantCount = 0,
    this.totalMemberCount = 0,

    // 멤버 타이머 상태 목록
    this.memberTimers = const [],

    // 에러 메시지 (있는 경우)
    this.errorMessage,

    // 해시태그 목록
    this.hashTags = const [],
  });

  final AsyncValue<TimerSession?> activeSession;
  final TimerStatus timerStatus;
  final int elapsedSeconds;
  final AsyncValue<List<TimerSession>> sessions;
  final String groupId;
  final String groupName;
  final int participantCount;
  final int totalMemberCount;
  final List<MemberTimer> memberTimers;
  final String? errorMessage;
  final List<String> hashTags;
}

// 타이머 상태 열거형
enum TimerStatus {
  initial, // 초기 상태
  running, // 실행 중
  paused, // 일시 정지
  completed, // 완료됨
}
