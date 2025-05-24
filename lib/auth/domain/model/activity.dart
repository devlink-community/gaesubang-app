// lib/auth/domain/model/activity.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity.freezed.dart';

@freezed
class Activity with _$Activity {
  const Activity({
    required this.timerStatus,
    this.sessionStartedAt,
    this.lastUpdatedAt,
    required this.currentSessionElapsedSeconds,
    required this.todayTotalSeconds,
    required this.dailyDurationsMap,
    required this.allTimeTotalSeconds,
  });

  final TimerStatus timerStatus;
  final DateTime? sessionStartedAt;
  final DateTime? lastUpdatedAt;
  final int currentSessionElapsedSeconds;
  final int todayTotalSeconds;
  final Map<String, int> dailyDurationsMap; // 일자별 활동 시간
  final int allTimeTotalSeconds;

  // 헬퍼 메서드들
  bool get isRunning =>
      timerStatus == TimerStatus.running || timerStatus == TimerStatus.resume;
  bool get isPaused => timerStatus == TimerStatus.paused;
  bool get isEnded => timerStatus == TimerStatus.end;

  // 현재 세션 경과 시간 (실시간 계산)
  int get currentElapsedSeconds {
    if (!isRunning || sessionStartedAt == null) {
      return currentSessionElapsedSeconds;
    }

    final now = DateTime.now();
    final diff = now.difference(sessionStartedAt!);
    return currentSessionElapsedSeconds + diff.inSeconds;
  }

  // HH:MM:SS 형식으로 변환
  String get elapsedTimeFormat {
    final totalSeconds = currentElapsedSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

// 타이머 상태 enum
enum TimerStatus {
  running,
  paused,
  resume,
  end;

  String get value {
    switch (this) {
      case TimerStatus.running:
        return 'running';
      case TimerStatus.paused:
        return 'paused';
      case TimerStatus.resume:
        return 'resume';
      case TimerStatus.end:
        return 'end';
    }
  }

  static TimerStatus fromString(String value) {
    switch (value) {
      case 'running':
        return TimerStatus.running;
      case 'paused':
        return TimerStatus.paused;
      case 'resume':
        return TimerStatus.resume;
      case 'end':
        return TimerStatus.end;
      default:
        return TimerStatus.end;
    }
  }
}
