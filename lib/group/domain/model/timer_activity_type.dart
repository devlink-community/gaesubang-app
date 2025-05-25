// lib/group/domain/model/timer_activity_type.dart
/// 타이머 활동 타입을 정의하는 enum
enum TimerActivityType {
  start,
  pause,
  resume,
  end;

  /// 문자열을 TimerActivityType으로 변환
  static TimerActivityType fromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'start':
        return TimerActivityType.start;
      case 'pause':
        return TimerActivityType.pause;
      case 'resume':
        return TimerActivityType.resume;
      case 'end':
        return TimerActivityType.end;
      default:
        throw ArgumentError('Unknown timer activity type: $typeString');
    }
  }

  /// TimerActivityType을 문자열로 변환
  String toStringValue() {
    switch (this) {
      case TimerActivityType.start:
        return 'start';
      case TimerActivityType.pause:
        return 'pause';
      case TimerActivityType.resume:
        return 'resume';
      case TimerActivityType.end:
        return 'end';
    }
  }

  /// 타이머 상태 문자열로 변환 - 파이어스토어 저장 값과 동일하게
  String toTimerStateString() {
    switch (this) {
      case TimerActivityType.start:
        return 'start';
      case TimerActivityType.pause:
        return 'pause';
      case TimerActivityType.resume:
        return 'resume';
      case TimerActivityType.end:
        return 'end';
    }
  }

  /// 활성 상태인지 확인
  bool get isActive =>
      this == TimerActivityType.start || this == TimerActivityType.resume;
}
