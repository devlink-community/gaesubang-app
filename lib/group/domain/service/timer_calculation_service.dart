// lib/group/domain/service/timer_calculation_service.dart
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:devlink_mobile_app/group/domain/model/timer_activity_type.dart';

/// 타이머 계산 관련 로직을 중앙 집중화하는 서비스 클래스
class TimerCalculationService {
  const TimerCalculationService._(); // 인스턴스화 방지

  /// 현재 경과 시간 계산 (초 단위)
  ///
  /// [isActive] 타이머 활성 상태
  /// [startTime] 현재 세션 시작 시간
  /// [baseElapsed] 기본 누적 시간 (초)
  /// 반환: 총 경과 시간 (초)
  static int calculateElapsedSeconds({
    required bool isActive,
    required DateTime? startTime,
    required int baseElapsed,
  }) {
    if (!isActive || startTime == null) return baseElapsed;

    // 활성 상태면 기본 누적 시간 + 현재 세션 경과 시간
    final now = TimeFormatter.nowInSeoul();
    return baseElapsed + now.difference(startTime).inSeconds;
  }

  /// 현재 경과 시간 계산 (분 단위)
  ///
  /// [isActive] 타이머 활성 상태
  /// [startTime] 현재 세션 시작 시간
  /// [baseElapsed] 기본 누적 시간 (초)
  /// 반환: 총 경과 시간 (분)
  static int calculateElapsedMinutes({
    required bool isActive,
    required DateTime? startTime,
    required int baseElapsed,
  }) {
    final seconds = calculateElapsedSeconds(
      isActive: isActive,
      startTime: startTime,
      baseElapsed: baseElapsed,
    );
    return seconds ~/ 60;
  }

  /// 타이머 상태에 따른 경과 시간 계산
  ///
  /// [timerState] 타이머 활동 상태
  /// [startTime] 현재 세션 시작 시간
  /// [baseElapsed] 기본 누적 시간 (초)
  /// 반환: 총 경과 시간 (초)
  static int calculateElapsedByState({
    required TimerActivityType timerState,
    required DateTime? startTime,
    required int baseElapsed,
  }) {
    final isActive =
        timerState == TimerActivityType.start ||
        timerState == TimerActivityType.resume;

    return calculateElapsedSeconds(
      isActive: isActive,
      startTime: startTime,
      baseElapsed: baseElapsed,
    );
  }

  /// GroupMember 모델에서 경과 시간 계산
  ///
  /// [member] 그룹 멤버 모델
  /// 반환: 총 경과 시간 (초)
  static int calculateMemberElapsed(GroupMember member) {
    return calculateElapsedByState(
      timerState: member.timerState,
      startTime: member.timerStartAt,
      baseElapsed: member.timerElapsed,
    );
  }

  /// 포맷팅된 시간 문자열 반환
  ///
  /// [seconds] 초 단위 시간
  /// 반환: HH:MM:SS 형식 문자열
  static String formatElapsedTime(int seconds) {
    return TimeFormatter.formatSeconds(seconds);
  }

  /// GroupMember 모델에서 포맷팅된 시간 문자열 반환
  ///
  /// [member] 그룹 멤버 모델
  /// 반환: HH:MM:SS 형식 문자열
  static String formatMemberElapsedTime(GroupMember member) {
    final seconds = calculateMemberElapsed(member);
    return formatElapsedTime(seconds);
  }

  /// 타이머 상태가 활성 상태인지 확인
  ///
  /// [timerState] 타이머 활동 상태
  /// 반환: 활성 상태 여부
  static bool isTimerActive(TimerActivityType timerState) {
    return timerState == TimerActivityType.start ||
        timerState == TimerActivityType.resume;
  }
}
