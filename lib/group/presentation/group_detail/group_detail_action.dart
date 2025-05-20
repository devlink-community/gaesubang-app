import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_detail_action.freezed.dart';

@freezed
sealed class GroupDetailAction with _$GroupDetailAction {
  // 타이머 시작 액션
  const factory GroupDetailAction.startTimer() = StartTimer;

  // 타이머 일시정지 액션
  const factory GroupDetailAction.pauseTimer() = PauseTimer;

  // 타이머 재개 액션
  const factory GroupDetailAction.resumeTimer() = ResumeTimer;

  // 타이머 종료 액션
  const factory GroupDetailAction.stopTimer() = StopTimer;

  // 타이머 초기화 액션
  const factory GroupDetailAction.resetTimer() = ResetTimer;

  // 그룹 ID 설정 액션
  const factory GroupDetailAction.setGroupId(String groupId) = SetGroupId;

  // 그룹 정보 설정 액션
  const factory GroupDetailAction.setGroupInfo(
    String groupName,
    List<String> hashTags,
  ) = SetGroupInfo;

  // 세션 목록 새로고침 액션
  const factory GroupDetailAction.refreshSessions() = RefreshSessions;

  // 타이머 틱 업데이트 액션 (1초마다 호출)
  const factory GroupDetailAction.timerTick() = TimerTick;

  // 타이머 토글 액션 (시작/일시정지)
  const factory GroupDetailAction.toggleTimer() = ToggleTimer;

  // 출석부(캘린더) 화면으로 이동
  const factory GroupDetailAction.navigateToAttendance() = NavigateToAttendance;

  // 지도 화면으로 이동
  const factory GroupDetailAction.navigateToMap() = NavigateToMap;

  // 그룹 설정 화면으로 이동
  const factory GroupDetailAction.navigateToSettings() = NavigateToSettings;

  // 사용자 프로필 화면으로 이동
  const factory GroupDetailAction.navigateToUserProfile(String userId) =
      NavigateToUserProfile;
  
  // 그룹 채팅 화면으로 이동 (새로 추가)
  const factory GroupDetailAction.navigateToChat() = NavigateToChat;
}
