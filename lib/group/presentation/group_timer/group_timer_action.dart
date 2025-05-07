import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_timer_action.freezed.dart';

@freezed
sealed class GroupTimerAction with _$GroupTimerAction {
  // 타이머 시작 액션
  const factory GroupTimerAction.startTimer() = StartTimer;

  // 타이머 일시정지 액션
  const factory GroupTimerAction.pauseTimer() = PauseTimer;

  // 타이머 재개 액션
  const factory GroupTimerAction.resumeTimer() = ResumeTimer;

  // 타이머 종료 액션
  const factory GroupTimerAction.stopTimer() = StopTimer;

  // 타이머 초기화 액션
  const factory GroupTimerAction.resetTimer() = ResetTimer;

  // 그룹 ID 설정 액션
  const factory GroupTimerAction.setGroupId(String groupId) = SetGroupId;

  // 세션 목록 새로고침 액션
  const factory GroupTimerAction.refreshSessions() = RefreshSessions;

  // 타이머 틱 업데이트 액션 (1초마다 호출)
  const factory GroupTimerAction.timerTick() = TimerTick;

  // 타이머 통계 보기 클릭 (화면 이동용)
  const factory GroupTimerAction.viewStatistics() = ViewStatistics;
}
