// lib/group/presentation/group_detail/group_detail_state.dart
import 'package:devlink_mobile_app/core/utils/time_formatter.dart';
import 'package:devlink_mobile_app/group/domain/model/group.dart';
import 'package:devlink_mobile_app/group/domain/model/group_member.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'group_detail_state.freezed.dart';

@freezed
class GroupDetailState with _$GroupDetailState {
  const GroupDetailState({
    // 타이머 현재 상태
    this.timerStatus = TimerStatus.stop,

    // 현재 타이머 경과 시간 (초)
    this.elapsedSeconds = 0,

    // 그룹 상세 정보 (AsyncValue로 감싸진 상태)
    this.groupDetailResult = const AsyncValue.loading(),

    // 멤버 목록 (AsyncValue로 감싸진 상태)
    this.groupMembersResult = const AsyncValue.loading(),

    // 🔧 새로 추가: 실시간 스트림 연결 상태
    this.streamConnectionStatus = StreamConnectionStatus.connecting,

    // 🔧 새로 추가: 마지막 스트림 업데이트 시간
    this.lastStreamUpdateTime,

    // 기존 에러 메시지 (단순하게 유지)
    this.errorMessage,

    // 🔧 새로 추가: 재연결 시도 횟수
    this.reconnectionAttempts = 0,

    // 🔧 새로 추가: 화면 활성 상태
    this.isScreenActive = true,

    // 🔧 새로 추가: 앱 포그라운드 상태
    this.isAppInForeground = true,
  });

  final TimerStatus timerStatus;
  final int elapsedSeconds;
  final AsyncValue<Group> groupDetailResult;
  final AsyncValue<List<GroupMember>> groupMembersResult;

  // 🔧 새로운 필드들
  final StreamConnectionStatus streamConnectionStatus;
  final DateTime? lastStreamUpdateTime;
  final String? errorMessage;
  final int reconnectionAttempts;
  final bool isScreenActive;
  final bool isAppInForeground;

  // 🔧 새로운 헬퍼 메서드들

  /// 실시간 업데이트가 정상적으로 작동하는지 확인
  bool get isStreamHealthy {
    if (streamConnectionStatus != StreamConnectionStatus.connected) {
      return false;
    }

    if (lastStreamUpdateTime == null) {
      return false;
    }

    // 5분 이상 업데이트가 없으면 비정상으로 간주
    final now = TimeFormatter.nowInSeoul();
    final timeSinceLastUpdate = now.difference(lastStreamUpdateTime!);
    return timeSinceLastUpdate.inMinutes < 5;
  }

  /// 재연결을 시도해야 하는지 확인
  bool get shouldAttemptReconnection =>
      streamConnectionStatus == StreamConnectionStatus.disconnected &&
      reconnectionAttempts < 3 &&
      isScreenActive &&
      isAppInForeground;

  /// 사용자에게 표시할 상태 메시지
  String? get statusMessage {
    if (!isScreenActive || !isAppInForeground) {
      return null; // 화면이 비활성 상태일 때는 상태 메시지 표시 안함
    }

    switch (streamConnectionStatus) {
      case StreamConnectionStatus.connecting:
        return null; // 🔧 연결 중 메시지 제거 (정상적인 상황)

      case StreamConnectionStatus.connected:
        if (!isStreamHealthy) {
          return '실시간 업데이트가 지연되고 있습니다.'; // 🔧 비정상 상황에만 표시
        }
        return null; // 정상 상태일 때는 메시지 없음

      case StreamConnectionStatus.disconnected:
        if (reconnectionAttempts > 0) {
          return '연결 재시도 중... (${reconnectionAttempts}/3)'; // 🔧 재연결 중일 때만 표시
        }
        return null; // 🔧 단순 연결 끊어짐은 메시지 제거

      case StreamConnectionStatus.failed:
        return '실시간 업데이트에 문제가 발생했습니다.'; // 🔧 실제 오류 상황
    }
  }

  /// 화면이 활성 상태인지 확인
  bool get isActive => isScreenActive && isAppInForeground;
}

// 🔧 새로운 열거형: 스트림 연결 상태
enum StreamConnectionStatus {
  /// 연결 시도 중
  connecting,

  /// 연결됨 (정상 작동)
  connected,

  /// 연결 끊어짐 (재연결 시도 가능)
  disconnected,

  /// 연결 실패 (재연결 불가능한 상태)
  failed,
}

// 타이머 상태 열거형 (기존 유지)
enum TimerStatus {
  running, // 실행 중
  paused, // 일시 정지
  stop, // 중지됨
}
